param name string = 'kau'

param environment string = 'dev'

param department string = 'gsc'

// param location string = resourceGroup().location

param location string = 'westeurope'

// param hbi_workspace bool = false

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: 'euvnet1'
  scope: resourceGroup('EURG')
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  parent: vnet
  name: 'default'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: '${name}stml${department}${environment}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${name}-kevault-${department}-${environment}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
  dependsOn: [
    storageAccount
  ]
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${name}-ai-${department}-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2022-05-01' = {
  name: '${name}-ml-${department}-${environment}'
  location: location
  properties: {
    friendlyName: '${name}-ml-${department}-${environment}'
    applicationInsights: appInsights.id
    keyVault: keyVault.id
    storageAccount: storageAccount.id
    publicNetworkAccess: 'Disabled'

  }
  identity: {
    type: 'SystemAssigned'
  }
}

module privateEndpoint './mlnetworking.bicep' = {
  name: '${name}-pe-${department}-${environment}'
  params: {
    location: location
    mlWorkspaceID: mlWorkspace.id
    subnetId: subnet.id
    virtualNetworkId: vnet.id
  }
}
// resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
//   name: '${name}-pe-${department}-${environment}'
//   location: location
//   properties: {
//     privateLinkServiceConnections: [
//       {
//         name: '${name}-plsc-${department}-${environment}'
//         properties: {
//           privateLinkServiceId: mlWorkspace.id
//           groupIds: [
//             'ml-workspace'
//           ]
//         }
//       }
//     ]
//     subnet: {
//       id: subnet.id
//     }
//   }
// }


