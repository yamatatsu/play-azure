// ============================================================================
// Container App - Web Server
// ============================================================================
//
// このモジュールはWebサーバー専用のContainer Appを作成します。
// 設定値は可読性のため直接記述しており、環境差分のみをパラメータ化しています。
//
// 仕様:
// - External Ingress (HTTPS公開)
// - ポート: 3000
// - リソース: 0.5 vCPU, 1Gi メモリ
// - スケール: 0-10レプリカ (HTTP同時リクエスト数ベース)
// - ヘルスチェック: GET / (Liveness & Readiness)
// - Managed Identity有効 (ACR Pull用)
// ============================================================================

@description('Azure region')
param location string

@description('Resource name prefix (e.g., yamatatsu-lab-v1-dev)')
param prefix string

@description('Tags for resources')
param tags object

@description('Container App Environment ID')
param containerAppEnvironmentId string

@description('Container Registry login server (e.g., registry.azurecr.io)')
param containerRegistryLoginServer string

@description('User Assigned Managed Identity ID')
param identityId string

@description('Container image name with tag (e.g., backend:latest)')
param containerImage string

@description('Environment variables (optional)')
param environmentVariables array = []

var containerAppName = '${prefix}-web'
var fullImageName = '${containerRegistryLoginServer}/${containerImage}'

resource containerApp 'Microsoft.App/containerApps@2025-01-01' = {
  name: containerAppName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    workloadProfileName: 'Consumption'
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
        transport: 'http'
        allowInsecure: false
        traffic: [{ latestRevision: true, weight: 100 }]
      }
      registries: [{ identity: identityId, server: containerRegistryLoginServer }]
    }
    template: {
      containers: [
        {
          name: 'web'
          image: fullImageName
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: environmentVariables
          probes: [
            { type: 'Liveness',  httpGet: { path: '/', port: 3000, scheme: 'HTTP' }, initialDelaySeconds: 30, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 3 }
            { type: 'Readiness', httpGet: { path: '/', port: 3000, scheme: 'HTTP' }, initialDelaySeconds: 15, periodSeconds: 5,  timeoutSeconds: 3, failureThreshold: 3 }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        rules: [
          {
            name: 'http-concurrent-requests'
            http: { metadata: { concurrentRequests: '10' } }
          }
        ]
      }
    }
  }
}

@description('Container App ID')
output containerAppId string = containerApp.id

@description('Container App name')
output containerAppName string = containerApp.name

@description('Container App FQDN')
output fqdn string = containerApp.properties.configuration.ingress.fqdn

@description('Container App latest revision name')
output latestRevisionName string = containerApp.properties.latestRevisionName
