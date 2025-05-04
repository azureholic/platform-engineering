param vnmName string = 'vnm-central'
param vnmNetworkGroupName string = 'ng-dynamic'
param vnetHubName string = 'vnet-hub'
param vnetResourceGroupName string
param useHubGateway bool

resource networkManager 'Microsoft.Network/networkManagers@2022-09-01' existing = {
  name: vnmName
}

resource networkGroup 'Microsoft.Network/networkManagers/networkGroups@2024-05-01' existing = {
  name: vnmNetworkGroupName
  parent: networkManager
}

resource vnetHub 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetHubName
  scope: resourceGroup(vnetResourceGroupName)
}


resource HubSpokeConfig 'Microsoft.Network/networkManagers/connectivityConfigurations@2024-05-01' = {
  parent: networkManager
  name: 'HubSpokeConfig'
  properties: {
    connectivityTopology: 'HubAndSpoke'
    hubs: [
      {
        resourceType: 'Microsoft.Network/virtualNetworks'
        resourceId: vnetHub.id
      }
    ]
    appliesToGroups: [
      {
        networkGroupId: networkGroup.id
        groupConnectivity: 'None'
        useHubGateway: string(useHubGateway)
        isGlobal: 'False'
      }
    ]
    deleteExistingPeering: 'True'
    isGlobal: 'False'
    description: 'Hub-Spoke Configuration'
  }
}
