param principalId string
param storeName string
param desc string = ''

resource configStore 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: storeName
}

@description('This is the built-in Key Vault Secrets Officer role.')
resource appConfigDataOwnerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b'
}

resource appConfigDataOwnerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, appConfigDataOwnerRoleDefinition.id)
  scope: configStore
  properties: {
    roleDefinitionId: appConfigDataOwnerRoleDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal' 
    description: desc
  }
}
