targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources except workload identity')
param location string

@minLength(1)
@description('location for workload identity')
param workloadIdentityLocation string

// https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli#supported-version-list
@description('The Kubernetes version.')
param kubernetesVersion string

@description('Specifies the names of the key-value resources. The name is a combination of key and label with $ as delimiter. The label is optional.')
param keyValueNames array = []

@description('Specifies the values of the key-value resources.')
param keyValueValues array = []

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var aksName = '${abbrs.containerServiceManagedClusters}${resourceToken}'

// Resource group to hold all resources
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// The Azure Container Registry to hold the images
module acr './resources/acr.bicep' = {
  name: 'container-registry'
  scope: resourceGroup
  params: {
    location: location
    name: '${abbrs.containerRegistry}${resourceToken}'
    tags: tags
  }
}

// The AKS cluster to host the application
module aks './resources/aks.bicep' = {
  name: 'aks'
  scope: resourceGroup
  params: {
    location: location
    name: aksName
    kubernetesVersion: kubernetesVersion
    tags: tags
  }
}

// the app config store to connect for config settings
module appconfig './resources/configstore.bicep' = {
  name: 'appc'
  scope: resourceGroup
  params: {
    location: location
    name: '${abbrs.appConfigStore}${resourceToken}'
    tags: tags
    keyValueNames: keyValueNames
    keyValueValues: keyValueValues
  }
}

// Grant ACR Pull access from cluster managed identity to container registry
module containerRegistryAccess './role-assignments/acr-pull.bicep' = {
  name: 'cluster-container-registry-access'
  scope: resourceGroup
  params: {
    aksPrincipalId: aks.outputs.clusterIdentity.objectId
    acrName: acr.outputs.name
    desc: 'AKS cluster managed identity'
  }
}

// Managed identity for application
module appManagedIdentity './resources/identity.bicep' = {
  name: 'app-managed-identity'
  scope: resourceGroup
  params: {
    managedIdentityName:  '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}-${workloadIdentityLocation}'
    federatedIdentityName:  '${abbrs.federatedIdentityCredentials}${resourceToken}-app'
    aksOidcIssuer: aks.outputs.aksOidcIssuer
    location: workloadIdentityLocation
    tags: tags
  }
}

// Assign App Configuration Data Owner role to the Workload identity
module keyvaultRoleAssignment './role-assignments/configstore-data-owner.bicep' = {
  name: 'assignAppConfigDataOwnerRole'
  scope: resourceGroup
  params: {
    principalId: appManagedIdentity.outputs.managedIdentityPrincipalId
    storeName: appconfig.outputs.name
    desc: 'workload identity identity'
  }
}

// Assign Network Contributor role to the aks cluster identity
module networkContributorRoleAssignment './role-assignments/ip-contributor.bicep' = {
  name: 'assignNetworkContributorRole'
  scope: resourceGroup
  params: {
    principalId: aks.outputs.controlPlaneIdentityObjectId
    ipName: aksName
    desc: 'aks cluster identity'
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_AKS_CLUSTER_NAME string = aks.outputs.name
output AZURE_STATIC_IP_NAME string = aks.outputs.name
output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_AKS_CLUSTERIDENTITY_OBJECT_ID string = aks.outputs.clusterIdentity.objectId
output AZURE_AKS_CLUSTERIDENTITY_CLIENT_ID string = aks.outputs.clusterIdentity.clientId
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name
output AZURE_APP_CONFIG_ENDPOINT string = appconfig.outputs.endpoint
output AZURE_MANAGED_IDENTITY_CLIENT_ID string = appManagedIdentity.outputs.managedIdentityClientId
