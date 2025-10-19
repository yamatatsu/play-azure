targetScope = 'resourceGroup'

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string

var appName = 'yamatatsu-lab-v1'
var prefix = '${appName}-${environment}'

var containerAppsSubnetPrefix = '10.0.0.0/23'

@description('Tags for all resources')
var tags = {
  environment: environment
  project: appName
  managedBy: 'bicep'
}

// 既存のKey Vaultへの参照
// このKey Vaultには、アプリケーションで使用するシークレットが格納されている想定
// bicepをデプロイする前に環境ごとに手動で作成しておく必要がある
// 
// まずは KeyVault がリソースプロバイダーに登録されていることを確認する
//   az provider show --namespace Microsoft.KeyVault --query "registrationState"
// 登録されていない場合は以下で登録
//   az provider register --namespace Microsoft.KeyVault
// 
// 開発環境の例:
//   az keyvault create \
//     --name yamatatsu-lab-v1-dev-kv \
//     --resource-group yamatatsu-lab \
//     --location japaneast \
//     --enable-rbac-authorization false \
//     --enabled-for-template-deployment true
//
// 加えて、PostgreSQLのadmin passwordも格納しておくこと
//   az keyvault secret set \
//     --vault-name yamatatsu-lab-v1-dev-kv \
//     --name "postgres-admin-password" \
//     --value "<your-postgres-admin-password>"
resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: '${prefix}-kv'
  scope: resourceGroup()
}


// ===========================================================================
// Modules

module nsg 'modules/nsg.bicep' = {
  name: '${prefix}-nsg-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
    containerAppsSubnetPrefix: containerAppsSubnetPrefix
  }
}

module natGateway 'modules/nat-gateway.bicep' = {
  name: '${prefix}-nat-gateway-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: '${prefix}-monitoring-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
  }
}

module network 'modules/network.bicep' = {
  name: '${prefix}-network-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
    containerAppsSubnetPrefix: containerAppsSubnetPrefix
    containerAppsNsgId: nsg.outputs.containerAppsNsgId
    postgresNsgId: nsg.outputs.postgresNsgId
    natGatewayId: natGateway.outputs.natGatewayId
  }
}

module postgresql 'modules/postgresql.bicep' = {
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
