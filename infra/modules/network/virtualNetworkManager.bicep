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

@description('This is the main IPAM pool for all locations')
resource ipamRootPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = {
  name: 'ipam-root-pool'
  parent: networkManager
  location: location
  properties: {
    description: 'IPAM Pool for all regions'
    addressPrefixes: [
      '10.0.0.0/8'
    ]
  }
}

@description('This is the main IPAM pool for uksouth')
resource ipamPoolWorkload1 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = {
  name: 'ipam-pool-alz-workload1'
  parent: networkManager
  location: location
  properties: {
    description: 'IPAM Pool for workload 1'
    addressPrefixes: [
      '10.100.0.0/16'
    ]
    parentPoolName: ipamRootPool.name
  }
}

@description('This is the main IPAM pool for sweden')
resource ipamPoolWorkload2 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = {
  // sometimes parallel deployment of pool fails...
  dependsOn: [ipamPoolWorkload1]
  name: 'ipam-pool-alz-workload2'
  parent: networkManager
  location: location
  properties: {
    description: 'IPAM Pool for workload 2'
    addressPrefixes: [
      '10.101.0.0/16'
    ]
    parentPoolName: ipamRootPool.name
  }
}

@description('This is the main IPAM pool for sweden')
resource ipamPoolWorkload3 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = {
  // sometimes parallel deployment of pool fails...
  dependsOn: [ipamPoolWorkload2]
  name: 'ipam-pool-alz-workload3'
  parent: networkManager
  location: location
  properties: {
    description: 'IPAM Pool for workload 3'
    addressPrefixes: [
      '10.102.0.0/16'
    ]
    parentPoolName: ipamRootPool.name
  }
}


output networkManagerName string = networkManager.name
output networkGroupName string = networkGroupSpokesDynamic.name
output ipamPoolName1 string = ipamPoolWorkload1.name
output ipamPoolName2 string = ipamPoolWorkload2.name
output ipamPoolName3 string = ipamPoolWorkload3.name
