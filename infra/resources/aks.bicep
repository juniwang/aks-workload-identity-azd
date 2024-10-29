param name string
param location string
param kubernetesVersion string

@description('Custom tags to apply to the resources')
param tags object = {}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: [
      {
        ipTagType: 'FirstPartyUsage'
        tag: '/AppConfigurationInternalDev'
      }
    ]
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-05-01' = {
  location: location
  name: name
  properties: {
    dnsPrefix: '${name}-dns'
    kubernetesVersion: kubernetesVersion
    enableRBAC: true

    ingressProfile: {
      webAppRouting: {
        enabled: true
      }
    }

    networkProfile: {
      loadBalancerSku: 'standard'
      loadBalancerProfile: {
        outboundIPs: {
          publicIPs: [{
            id: publicIp.id
          }]
        }
      }
      outboundType: 'loadBalancer'
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkPolicy: 'azure'
    }

    agentPoolProfiles: [
      {
        name: 'systempool'
        osDiskSizeGB: 0 // default size
        osDiskType: 'Ephemeral'
        enableAutoScaling: true
        count: 1
        minCount: 1
        maxCount: 3
        vmSize: 'Standard_DS4_v2'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 250
        nodeLabels: {
        }
        nodeTaints: []
        enableNodePublicIP: false
        tags: tags
      }
      {
        name: 'workerpool'
        osDiskSizeGB: 0 // default size
        osDiskType: 'Ephemeral'
        enableAutoScaling: true
        count: 1
        minCount: 1
        maxCount: 3
        vmSize: 'Standard_DS4_v2'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        maxPods: 250
        nodeLabels: {
        }
        nodeTaints: []
        enableNodePublicIP: false
        tags: tags
      }
    ]

    apiServerAccessProfile: {
      enablePrivateCluster: false
    }

    autoUpgradeProfile: {
      upgradeChannel: 'node-image'
      nodeOSUpgradeChannel: 'NodeImage'
    }

    oidcIssuerProfile: {
      enabled: true
    }
   
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
  }
  tags: tags
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

@description('The AKS cluster identity')
output clusterIdentity object = {
  clientId: aks.properties.identityProfile.kubeletidentity.clientId
  objectId: aks.properties.identityProfile.kubeletidentity.objectId
  resourceId: aks.properties.identityProfile.kubeletidentity.resourceId
}
output controlPlaneIdentityObjectId string = aks.identity.principalId
output name string = aks.name
output aksOidcIssuer string = aks.properties.oidcIssuerProfile.issuerURL
