@description('Resource name prefix (appName-environment)')
param prefix string

@description('Location for all resources')
param location string

@description('Tags for resources')
param tags object = {}

@description('Container Apps subnet address prefix')
param containerAppsSubnetPrefix string

// ============================================================================
// Container Apps NSG
// ============================================================================
//
// 公式ドキュメント:
// https://learn.microsoft.com/azure/container-apps/firewall-integration
//
// ネットワークアーキテクチャ:
// Internet → Azure Load Balancer (マネージド) → Envoy Proxy → Container App
//
// 重要: Container Appsは直接インターネットに晒されません。
// すべてのトラフィックはAzureのマネージドLoad BalancerとEnvoy Proxyを経由します。
// Container AppsはEnvoy Proxyからのトラフィックのみを受信します（内部通信）。
//
// 多層防御:
// 1. Azure Load Balancer: TLS終端, DDoS Protection, ヘルスチェック
// 2. NSG (このリソース): サブネットレベルのファイアウォール
// 3. Container Apps Ingress: HTTPルーティング, IP制限, Easy Auth
// 4. アプリケーション: 認証, 認可, 入力バリデーション
//
// セキュリティルールの説明 (Consumption環境):
// - AllowHttpsInbound & AllowHttpInbound:
//     目的: ユーザートラフィックをAzure Load Balancerに許可（Container Appsへの直接アクセスではない）
//     フロー: Internet (443/80) → Load Balancer → Envoy Proxy → Container App
//     注意: Container Appsは内部ポート（例: 8080）でリッスンし、443/80では直接待ち受けしない
//
// - AllowAzureLoadBalancerProbes:
//     目的: Azure Load Balancerからのヘルスプローブを許可
//     ポート: 30000-32767 (公式ドキュメントで指定されたヘルスプローブポート範囲)
//     要件: Container Appsが正常に動作するために必須
//     フロー: Load Balancer → ヘルスチェックエンドポイント (30000-32767) → Container Apps基盤
//     注意: このルールがないとヘルスプローブが失敗し、トラフィックがルーティングされない
//
// これら3つのルールはそれぞれ異なる目的を持ち、すべて必要です:
// 1. ユーザートラフィック (HTTPS/HTTP on 443/80)
// 2. インフラヘルスチェック (AzureLoadBalancer on 30000-32767)
// ============================================================================
resource containerAppsNsg 'Microsoft.Network/networkSecurityGroups@2024-10-01' = {
  name: '${prefix}-containerapps-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          description: 'Allow HTTPS inbound from Internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHttpInbound'
        properties: {
          description: 'Allow HTTP inbound from Internet (for HTTPS redirect)'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerProbes'
        properties: {
          description: 'Allow Azure Load Balancer health probes (ports 30000-32767)'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '30000-32767'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

// ============================================================================
// PostgreSQL NSG
// ============================================================================
//
// セキュリティポリシー:
// - Container Appsサブネットからのみ、PostgreSQL接続（ポート5432）を許可
// - その他すべてのインバウンドトラフィックはAzureのデフォルトセキュリティルールで拒否
//
// なぜ明示的な "DenyAll" ルールがないのか？
// Azure NSGには組み込みのデフォルトルール（優先度65000以降）が存在:
//   65000: AllowVNetInBound (VNet内部トラフィックを許可、Azure管理トラフィックを含む)
//   65001: AllowAzureLoadBalancerInBound (ヘルスプローブを許可)
//   65500: DenyAllInBound (その他すべてを拒否)
//
// 明示的な "DenyAll" ルールを追加すると:
// - Azureインフラトラフィック（バックアップ、HAレプリケーション、監視）をブロック
// - AzureLoadBalancerとVirtualNetworkをブロックする警告が表示される
// - 冗長（デフォルトルール65500が既にマッチしないトラフィックを拒否）
//
// 現在の動作:
// ✅ Container Apps (10.0.0.0/23) → PostgreSQL (5432): 許可
// ✅ Azure管理トラフィック: 許可（デフォルトルール経由）
// ❌ Internet → PostgreSQL: 拒否（デフォルトルール65500経由）
// ❌ その他のサブネット → PostgreSQL: 拒否（デフォルトルール65500経由）
// ============================================================================
resource postgresNsg 'Microsoft.Network/networkSecurityGroups@2024-10-01' = {
  name: '${prefix}-postgres-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowPostgreSQLFromContainerApps'
        properties: {
          description: 'Allow PostgreSQL from Container Apps subnet only'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5432'
          sourceAddressPrefix: containerAppsSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

output containerAppsNsgId string = containerAppsNsg.id
output containerAppsNsgName string = containerAppsNsg.name
output postgresNsgId string = postgresNsg.id
output postgresNsgName string = postgresNsg.name
