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

module network 'modules/network.bicep' = {
  name: '${prefix}-network-deployment'
  params: {
    location: location
    prefix: prefix
    tags: tags
  }
}
