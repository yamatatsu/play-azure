@description('Resource name prefix (appName-environment)')
param prefix string

@description('Location for all resources')
param location string

@description('Tags for resources')
param tags object = {}

// ============================================================================
// Log Analytics Workspace
// ============================================================================
//
// 目的:
// - Container Appsのコンテナログを集約
// - PostgreSQLのクエリログ・監視ログを集約
// - NSGフローログを集約（オプション）
// - システムログの中央管理
//
// 保持期間:
// - デフォルト: 30日
// - 最大: 730日（2年）
// - コスト考慮: 開発環境は短め、本番環境は長めに設定
// ============================================================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: '${prefix}-logs'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1  // 無制限（-1）
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================================================
// Application Insights
// ============================================================================
//
// 目的:
// - アプリケーションパフォーマンス監視（APM）
// - リクエスト追跡・分散トレーシング
// - 例外・エラー追跡
// - カスタムメトリクス・イベント
// - ライブメトリクスストリーム
//
// 統合:
// - Log Analytics Workspaceに接続（ワークスペースベースモード）
// - Container Appsから自動的にテレメトリ送信
// - アプリケーションSDKでより詳細なトレーシング
//
// 公式ドキュメント:
// https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview
// ============================================================================

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${prefix}-appinsights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}

output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsWorkspaceName string = logAnalytics.name
output logAnalyticsCustomerId string = logAnalytics.properties.customerId
output applicationInsightsId string = applicationInsights.id
output applicationInsightsName string = applicationInsights.name
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
