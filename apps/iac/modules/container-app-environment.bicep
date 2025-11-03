// ============================================================================
// Container Apps Environment
// ============================================================================
//
// 複数のContainer Appを管理する環境を作成します。
//
// 仕様:
// - VNet統合 (Container Apps Subnet)
// - External Ingress対応 (internal: false)
// - Consumptionワークロードプロファイル
// - Log Analytics統合 (prod/staging環境のみ)
// - Application Insights統合 (prod/staging環境のみ)
// ============================================================================

@description('Azure region')
param location string

@description('Resource name prefix (e.g., yamatatsu-lab-v1-dev)')
param prefix string

@description('Tags for resources')
param tags object

@description('Container Apps Subnet ID')
param containerAppsSubnetId string

@description('Log Analytics Workspace ID (empty string for dev environment)')
param logAnalyticsWorkspaceId string

@description('Application Insights Connection String (empty string for dev environment)')
@secure()
param appInsightsConnectionString string

var environmentName = '${prefix}-cae'

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2025-01-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: containerAppsSubnetId
      internal: false
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
      }
    }
    daprAIConnectionString: appInsightsConnectionString
    // Workload Profiles (V2) - 推奨方式
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

@description('Container App Environment ID')
output containerAppEnvironmentId string = containerAppEnvironment.id

@description('Container App Environment name')
output containerAppEnvironmentName string = containerAppEnvironment.name

@description('Container App Environment default domain')
output defaultDomain string = containerAppEnvironment.properties.defaultDomain

@description('Container App Environment static IP')
output staticIp string = containerAppEnvironment.properties.staticIp
