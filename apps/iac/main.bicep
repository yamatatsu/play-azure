targetScope = 'resourceGroup'

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string

var prefix = 'myapp-${environment}'


module network 'modules/network.bicep' = {
  name: '${prefix}-network'
  params: {
    location: location
  }
}
