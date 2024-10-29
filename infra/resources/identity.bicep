param managedIdentityName string
param federatedIdentityName string
param serviceAccountNamespace string = 'test-app'
param serviceAccountName string = 'myapp'
param location string
param aksOidcIssuer string

@description('Custom tags to apply to the resources')
param tags object = {}

resource appManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

resource appFederatedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: federatedIdentityName
  parent: appManagedIdentity
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: aksOidcIssuer
    subject: 'system:serviceaccount:${serviceAccountNamespace}:${serviceAccountName}'
  }
}

output managedIdentityPrincipalId string = appManagedIdentity.properties.principalId
output managedIdentityClientId string = appManagedIdentity.properties.clientId

