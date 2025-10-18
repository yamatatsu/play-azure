@description('Resource name prefix (appName-environment)')
param prefix string

@description('Location for all resources')
param location string

@description('Tags for resources')
param tags object = {}

@description('VNet address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Container Apps subnet prefix')
param containerAppsSubnetPrefix string = '10.0.0.0/23'

@description('PostgreSQL subnet prefix')
param postgresSubnetPrefix string = '10.0.2.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${prefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
  }
}

resource containerAppsSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: vnet
  name: 'containerapps-subnet'
  properties: {
    addressPrefix: containerAppsSubnetPrefix
    delegations: [
      {
        name: 'Microsoft.App.environments'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
  }
}

resource postgresSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: vnet
  name: 'postgres-subnet'
  properties: {
    addressPrefix: postgresSubnetPrefix
    delegations: [
      {
        name: 'Microsoft.DBforPostgreSQL.flexibleServers'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output containerAppsSubnetId string = containerAppsSubnet.id
output postgresSubnetId string = postgresSubnet.id
