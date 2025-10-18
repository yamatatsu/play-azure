targetScope = 'resourceGroup'

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string

var appName = 'myapp'
var prefix = '${appName}-${environment}'

@description('Tags for all resources')
var tags = {
  environment: environment
  project: appName
  managedBy: 'bicep'
}

module nsg 'modules/nsg.bicep' = {
  name: '${prefix}-nsg-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
    containerAppsSubnetPrefix: '10.0.0.0/23'
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
    containerAppsNsgId: nsg.outputs.containerAppsNsgId
    postgresNsgId: nsg.outputs.postgresNsgId
    natGatewayId: natGateway.outputs.natGatewayId
  }
}
