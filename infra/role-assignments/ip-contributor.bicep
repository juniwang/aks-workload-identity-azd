param principalId string
param ipName string
param desc string = ''

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' existing = {
  name: ipName
}

resource networkContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: '4d97b98b-1d4f-4787-a291-c67834d212e7'
}

resource pipRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, networkContributorRoleDefinition.id)
  scope: publicIp
  properties: {
    roleDefinitionId: networkContributorRoleDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal' 
    description: desc
  }
}
