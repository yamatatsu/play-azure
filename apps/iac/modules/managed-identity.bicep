// ============================================================================
// User Assigned Managed Identity
// ============================================================================
//
// Container AppがACRからイメージをpullするためのManaged Identityを作成します。
//
// 利点:
// - パスワード管理が不要
// - セキュリティベストプラクティスに準拠
// - 1回のデプロイで完結（System Assigned Identityと異なり、2段階不要）
//
// ============================================================================

@description('Azure region')
param location string

@description('Resource name prefix (e.g., yamatatsu-lab-v1-dev)')
param prefix string

@description('Tags for resources')
param tags object

var identityName = '${prefix}-identity'

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: tags
}

@description('Managed Identity ID')
output identityId string = userAssignedIdentity.id

@description('Managed Identity name')
output identityName string = userAssignedIdentity.name

@description('Managed Identity principal ID')
output principalId string = userAssignedIdentity.properties.principalId

@description('Managed Identity client ID')
output clientId string = userAssignedIdentity.properties.clientId
