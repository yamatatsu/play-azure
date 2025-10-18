@description('Resource name prefix (appName-environment)')
param prefix string

@description('Location for all resources')
param location string

@description('Tags for resources')
param tags object = {}

// ============================================================================
// NAT Gateway and Public IP
// ============================================================================
//
// 目的:
// - Container Appsのアウトバウンド通信の送信元IPを固定
// - 外部API呼び出し時のIP許可リスト対応
// - SNAT (Source Network Address Translation) ポート枯渇の防止
//
// 利点:
// - 1つのパブリックIPで64,000ポート確保
// - 外部サービスのファイアウォール設定が容易
// - ログ追跡・監査要件への対応
//
// 接続:
// Container Apps Subnetに関連付けることで、
// そのサブネットからのすべてのアウトバウンドトラフィックが
// このNAT GatewayのパブリックIPから送信される
// ============================================================================

// Public IP for NAT Gateway
resource natPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${prefix}-nat-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
}

// NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2023-05-01' = {
  name: '${prefix}-nat-gateway'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    // この tier について、本来は不要な設定である。
    // NAT Gateway に tier という指定は存在しない。
    // しかし、what-if実行時に差分として判定されてしまい、未デプロイの差分が存在するかのように見えてしまう。
    // ここでは警告を許容し、差分検出されないように無駄な設定を残すこととする。
    // see, https://github.com/Azure/bicep/issues/5873
    tier: 'Regional'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: natPublicIp.id
      }
    ]
  }
}

output natGatewayId string = natGateway.id
output natGatewayName string = natGateway.name
output natPublicIpId string = natPublicIp.id
output natPublicIpAddress string = natPublicIp.properties.ipAddress
