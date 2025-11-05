// ============================================================================
// ACR Pull Role Assignment
// ============================================================================
//
// Managed IdentityにACR Pullロールを付与するモジュール
// これにより、Container AppがACRからイメージをpullできるようになります。
//
// ロールID: 7f951dda-4ed3-4680-a7ca-43fe172d538d (AcrPull)
//
// ============================================================================

@description('ACR name')
param acrName string

@description('Principal ID of the Managed Identity')
param principalId string

// 既存のACRリソースを参照
resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' existing = {
  name: acrName
}

// ACR Pullロールを付与
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

@description('Role assignment ID')
output roleAssignmentId string = acrPullRoleAssignment.id
