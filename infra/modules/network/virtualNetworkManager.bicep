@description('Location of the virtual network manager')
param location string = resourceGroup().location
param vnmName string = 'vnm-central'
param vnmNetworkGroupName string = 'ng-dynamic'

@description('This is the Azure Virtual Network Manager which will be used to implement the connected group for inter-vnet connectivity.')
resource networkManager 'Microsoft.Network/networkManagers@2022-09-01' = {
  name: vnmName
  location: location
  properties: {
    networkManagerScopeAccesses: [
      'Connectivity'
    ]
    networkManagerScopes: {
      subscriptions: [
        '/subscriptions/${subscription().subscriptionId}'
      ]
      managementGroups: []
    }
  }
}

@description('This is the dynamic group for all VNETs.')
resource networkGroupSpokesDynamic 'Microsoft.Network/networkManagers/networkGroups@2024-05-01' = {
  name: vnmNetworkGroupName
  parent: networkManager
  properties: {
    description: 'Network Group - Dynamic'
  }
}



output networkManagerName string = networkManager.name
output networkGroupName string = networkGroupSpokesDynamic.name
