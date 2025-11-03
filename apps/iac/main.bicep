// ============================================================================
// Azure Container Apps アーキテクチャ - メインテンプレート
// ============================================================================
//
// このBicepファイルは、Azure Container Appsを中心としたインフラストラクチャ全体を定義します。
// 詳細な設計書は README.md を参照してください。
//
// デプロイ対象リソース:
// - VNet (10.0.0.0/16)
//   - Container Apps Subnet (10.0.0.0/23)
//   - PostgreSQL Subnet (10.0.2.0/24)
// - Network Security Groups (NSG)
// - NAT Gateway (staging/prod環境のみ)
// - Log Analytics + Application Insights
// - PostgreSQL Flexible Server (staging/prod環境のみ)
// - Azure Container Registry (Standard SKU)
// - Container Apps Environment (Consumption)
// - Container App - Web Server (External Ingress, 0-10レプリカ)
//
// ============================================================================

targetScope = 'resourceGroup'

// ===========================================================================
// パラメータ・変数
// ===========================================================================

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string

// アプリケーション名とリソース名のプレフィックス
var appName = 'yamatatsu-lab-v1'
var prefix = '${appName}-${environment}'

// ネットワーク設定
var containerAppsSubnetPrefix = '10.0.0.0/23'

// すべてのリソースに付与するタグ
var tags = {
  environment: environment
  project: appName
  managedBy: 'bicep'
}

// ===========================================================================
// 既存リソース参照
// ===========================================================================

// Key Vault (事前に手動で作成済みの想定)
// PostgreSQLのadmin passwordなど、機密情報を格納
//
// 作成コマンド例:
//   az keyvault create \
//     --name yamatatsu-lab-v1-dev-kv \
//     --resource-group yamatatsu-lab \
//     --location japaneast \
//     --enable-rbac-authorization false \
//     --enabled-for-template-deployment true
//
//   az keyvault secret set \
//     --vault-name yamatatsu-lab-v1-dev-kv \
//     --name "postgres-admin-password" \
//     --value "<strong-password>"
resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: '${prefix}-kv'
  scope: resourceGroup()
}

// ===========================================================================
// ネットワーク基盤
// ===========================================================================

// Network Security Groups
// - Container Apps Subnet用: HTTPS (443), HTTP (80) を許可
// - PostgreSQL Subnet用: Container Apps SubnetからのPostgreSQL (5432) を許可
module nsg 'modules/nsg.bicep' = {
  name: '${prefix}-nsg-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
    containerAppsSubnetPrefix: containerAppsSubnetPrefix
  }
}

// NAT Gateway (staging/prod環境のみ)
// 固定送信元IPを提供し、外部APIのIP許可リスト対応を可能にする
module natGateway 'modules/nat-gateway.bicep' = if (environment != 'dev') {
  name: '${prefix}-nat-gateway-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
  }
}

// VNet & Subnets
// - VNet: 10.0.0.0/16
// - Container Apps Subnet: 10.0.0.0/23 (512 IPs)
// - PostgreSQL Subnet: 10.0.2.0/24 (256 IPs)
module network 'modules/network.bicep' = {
  name: '${prefix}-network-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
    containerAppsSubnetPrefix: containerAppsSubnetPrefix
    containerAppsNsgId: nsg.outputs.containerAppsNsgId
    postgresNsgId: nsg.outputs.postgresNsgId
    natGatewayId: natGateway.?outputs.natGatewayId
  }
}

// ===========================================================================
// 監視基盤
// ===========================================================================

// Log Analytics Workspace + Application Insights
// 全Container Appsのログとテレメトリを集約
module monitoring 'modules/monitoring.bicep' = {
  name: '${prefix}-monitoring-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
  }
}

// ===========================================================================
// データベース
// ===========================================================================

// PostgreSQL Flexible Server (staging/prod環境のみ)
// - VNet統合 (Private Access)
// - Zone-Redundant HA (prod環境)
// - Burstable tier (staging), General Purpose tier (prod)
module postgresql 'modules/postgresql.bicep' = if (environment != 'dev') {
  name: '${prefix}-postgresql-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
    environment: environment
    postgresSubnetId: network.outputs.postgresSubnetId
    administratorPassword: keyVault.getSecret('postgres-admin-password')
  }
}

// ===========================================================================
// Container Apps
// ===========================================================================

// Azure Container Registry
// Dockerイメージを保管
// - SKU: Standard
// - Admin User有効 (開発時の利便性のため)
module containerRegistry 'modules/container-registry.bicep' = {
  name: '${prefix}-acr-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
  }
}

// Container Apps Environment
// 複数のContainer Appを管理する共有環境
// - VNet統合
// - Consumptionプラン
// - Log Analytics統合
module containerAppEnvironment 'modules/container-app-environment.bicep' = {
  name: '${prefix}-cae-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
    containerAppsSubnetId: network.outputs.containerAppsSubnetId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    appInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
  }
}

// Container App - Web Server
// HTTPSで公開されるWebサーバー
// - イメージ: backend:latest (apps/backend/Dockerfileからビルド)
// - ポート: 3000
// - スケール: 0-10レプリカ (HTTP同時リクエスト数ベース)
// - リソース: 0.5 vCPU, 1Gi メモリ
// - Managed Identity有効 (ACRからイメージをpull)
module webServerApp 'modules/container-app-web.bicep' = {
  name: '${prefix}-web-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
    containerAppEnvironmentId: containerAppEnvironment.outputs.containerAppEnvironmentId
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerImage: 'backend:latest'
    environmentVariables: []
  }
}

// Container AppのManaged IdentityにACR Pullロールを付与
// これにより、Container AppがACRからイメージをpullできる
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, '${prefix}-web', 'acrpull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: webServerApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// ===========================================================================
// Outputs
// ===========================================================================

@description('Container Registry login server (e.g., yamatatsuv1devacr.azurecr.io)')
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer

@description('Container Registry name (e.g., yamatatsuv1devacr)')
output containerRegistryName string = containerRegistry.outputs.containerRegistryName

@description('Container App Environment name')
output containerAppEnvironmentName string = containerAppEnvironment.outputs.containerAppEnvironmentName

@description('Container App Environment default domain')
output containerAppEnvironmentDefaultDomain string = containerAppEnvironment.outputs.defaultDomain

@description('Web Server App FQDN (e.g., yamatatsu-lab-v1-dev-web.redpond-12345678.japaneast.azurecontainerapps.io)')
output webServerFqdn string = webServerApp.outputs.fqdn

@description('Web Server App name')
output webServerAppName string = webServerApp.outputs.containerAppName
