// ============================================================================
// Azure Container Registry
// ============================================================================
//
// Dockerイメージを保管するためのコンテナレジストリを作成します。
//
// 仕様:
// - SKU: Standard (本番環境ではPremiumも検討可能)
// - Admin User: 有効 (開発時の利便性のため、本番ではManaged Identity推奨)
// - パブリックアクセス: 有効
// - ゾーン冗長: 無効 (Premium SKUでのみ利用可能)
//
// 命名規則:
// - ACRの名前はグローバルに一意である必要があるため、ハイフンを削除
// - 例: yamatatsu-lab-v1-dev → yamatatsuv1devacr
// ============================================================================

@description('Azure region')
param location string

@description('Resource name prefix (e.g., yamatatsu-lab-v1-dev)')
param prefix string

@description('Tags for resources')
param tags object

// ACR名はグローバルに一意である必要があり、ハイフンを含めることができない
var acrName = replace('${prefix}acr', '-', '')

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}

@description('Container Registry ID')
output containerRegistryId string = containerRegistry.id

@description('Container Registry name')
output containerRegistryName string = containerRegistry.name

@description('Container Registry login server (e.g., registry.azurecr.io)')
output loginServer string = containerRegistry.properties.loginServer
