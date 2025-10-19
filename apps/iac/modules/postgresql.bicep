@description('Resource name prefix (appName-environment)')
param prefix string

@description('Location for all resources')
param location string

@description('Tags for resources')
param tags object = {}

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('PostgreSQL subnet resource ID')
param postgresSubnetId string

@description('PostgreSQL administrator password')
@secure()
param administratorPassword string

// ============================================================================
// PostgreSQL Flexible Server
// ============================================================================
//
// 公式ドキュメント:
// https://learn.microsoft.com/azure/postgresql/flexible-server/
//
// ネットワーク構成:
// - VNet統合（Private Access）
// - Private DNS Zone自動作成
// - SSL/TLS接続必須
//
// 高可用性:
// - 開発環境: HA無効（コスト削減）
// - 本番環境: Zone-Redundant HA有効（自動フェイルオーバー）
//
// SKU:
// - 開発環境: Burstable (B1ms) - 安価、バースト可能
// - 本番環境: GeneralPurpose (D2ds_v4) - 高性能、安定
//
// バックアップ:
// - 自動バックアップ: 7日間保持
// - ポイントインタイムリストア対応
// - Geo-Redundantバックアップ: 本番環境で検討
//
//
// [APPENDIX] なぜこの構成が必要か？
//
// 1. Private DNS Zoneの役割:
//    PostgreSQL Flexible ServerはVNet統合時にプライベートIPアドレスを取得します。
//    接続にはFQDN（例: yamatatsu-lab-v1-dev-postgres.postgres.database.azure.com）を使用しますが、
//    このFQDNをプライベートIPに解決するためにPrivate DNS Zoneが必要です。
//
// 2. VNet Linkの役割:
//    Private DNS Zoneは独立したリソースなので、どのVNetから参照できるかを明示的に
//    設定する必要があります。VNet Linkを作成することで、VNet内のリソース
//    （Container Appsなど）がPrivate DNS Zoneを使った名前解決を行えます。
//
// 3. データフロー:
//    Container Apps
//      → 接続要求: yamatatsu-lab-v1-dev-postgres.postgres.database.azure.com
//      → VNet（Private DNS Zone経由で名前解決）
//      → プライベートIP: 10.0.2.x
//      → PostgreSQL Flexible Server
//
// Public Access方式について:
// PostgreSQL Flexible Serverには「Public Access（パブリックアクセス）」方式もあります。
// この方式ではパブリックIPアドレスを持ち、ファイアウォールルールでアクセス制限を行います。
// Private DNS Zoneは不要でシンプルですが、以下の理由で推奨しません:
//
// - セキュリティ: インターネット経由のアクセスとなりリスクが高い
// - レイテンシ: VNet内通信と比較してレイテンシが高い
// - コスト: VNet内通信は無料だが、インターネット経由はデータ転送コストがかかる
// - Container Appsとの相性: 両方ともVNet内に配置する構成では、プライベート通信が最適
// ============================================================================

var administratorLogin = 'pgadmin'
var databaseName = 'appdb'

// SKU設定（環境ごと）
var skuConfig = {
  dev: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  staging: {
    name: 'Standard_D2ds_v4'
    tier: 'GeneralPurpose'
  }
  prod: {
    name: 'Standard_D2ds_v4'
    tier: 'GeneralPurpose'
  }
}

// HA設定（環境ごと）
var haEnabled = environment == 'prod' ? 'ZoneRedundant' : 'Disabled'

// Storage設定
var storageConfig = {
  storageSizeGB: 32
  autoGrow: 'Enabled'
}

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: '${prefix}.postgres.database.azure.com'
  location: 'global'
  tags: tags
}

// Virtual Network Link for Private DNS Zone
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: '${prefix}-vnet-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: substring(postgresSubnetId, 0, lastIndexOf(postgresSubnetId, '/subnets/'))
    }
  }
}

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: '${prefix}-postgres'
  location: location
  tags: tags
  sku: skuConfig[environment]
  properties: {
    version: '15'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: storageConfig.storageSizeGB
      autoGrow: storageConfig.autoGrow
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: haEnabled
    }
    network: {
      delegatedSubnetResourceId: postgresSubnetId
      privateDnsZoneArmResourceId: privateDnsZone.id
    }
  }
  dependsOn: [
    privateDnsZoneVnetLink
  ]
}

// Database
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgresServer
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// PostgreSQL Configuration - クエリログ設定（明示的に無効化）
// 開発環境では詳細なクエリログを有効化することも可能
// log_statement: 'none' (無効), 'ddl', 'mod', 'all'
resource postgresConfig 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2024-08-01' = {
  parent: postgresServer
  name: 'log_statement'
  properties: {
    value: 'none'
    source: 'user-override'
  }
}

output postgresServerId string = postgresServer.id
output postgresServerName string = postgresServer.name
output postgresServerFqdn string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = database.name
output connectionString string = 'postgresql://${administratorLogin}@${postgresServer.name}:***@${postgresServer.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
