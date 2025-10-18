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

@description('PostgreSQL administrator login name')
param administratorLogin string = 'pgadmin'

@description('PostgreSQL administrator password')
@secure()
param administratorPassword string

@description('PostgreSQL version')
param postgresVersion string = '15'

@description('Database name to create')
param databaseName string = 'appdb'

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
// ============================================================================

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
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${prefix}.postgres.database.azure.com'
  location: 'global'
  tags: tags
}

// Virtual Network Link for Private DNS Zone
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
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
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: '${prefix}-postgres'
  location: location
  tags: tags
  sku: {
    name: skuConfig[environment].name
    tier: skuConfig[environment].tier
  }
  properties: {
    version: postgresVersion
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
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-03-01-preview' = {
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
resource postgresConfig 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2023-03-01-preview' = {
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
