targetScope = 'subscription'

var location = deployment().location
param vnetHubName string = 'vnet-hub' 
param vnetSpokeName string = 'vnet-spoke'
param vnetResourceGroupName string

param vnmResourceGroupName string
param vnmName string = 'vnm-central'
param vnmNetworkGroupName string = 'ng-dynamic'

resource vnmRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: vnmResourceGroupName
  location: location
}

resource networkRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: vnetResourceGroupName
  location: location
}

module vnm 'modules/network/virtualNetworkManager.bicep' = {
  name: vnmName
  scope: vnmRg
  params: {
    location: location
    vnmName: vnmName
    vnmNetworkGroupName: vnmNetworkGroupName
  }
}

// define a root pool
module rootPool 'modules/network/ipamPool.bicep' = {
  name: 'ipam-pool-root'
  scope: vnmRg
  params: {
    ipamPoolAddressPrefixes:[
      '10.0.0.0/8'
    ]
    ipamPoolDescription: 'Root IPAM Pool'
    location: location
    ipamPoolName: 'root-pool'
    vnmName: vnm.outputs.networkManagerName
  }
}

// define a child pool for the hub
module hubPool 'modules/network/ipamPool.bicep' = {
  name: 'hubPool'
  scope: vnmRg
  params: {
    ipamPoolAddressPrefixes: [
      '10.10.0.0/16'
    ]
    ipamPoolDescription: 'Hub Pool'
    location: location
    ipamPoolName: 'hub-pool'
    vnmName: vnm.outputs.networkManagerName
    ipamParentPoolName: rootPool.outputs.ipamPoolName
  }
}

// define a child pool for a landingzone
module lzPool 'modules/network/ipamPool.bicep' = {
  name: 'lzPool'
  scope: vnmRg
  params: {
    ipamPoolAddressPrefixes: [
      '10.100.0.0/16'
    ]
    ipamPoolDescription: 'Landing Zone Pool'
    location: location
    ipamPoolName: 'lz-01-pool'
    vnmName: vnm.outputs.networkManagerName
    ipamParentPoolName: rootPool.outputs.ipamPoolName
  }
}



module autojoinPolicy 'modules/policy/dynamicNetworkGroupPolicy.bicep' = {
  name: 'autojoin-policy'
  params: {
    networkGroupName: vnm.outputs.networkGroupName
    vnetResourceGroupName: networkRg.name
    vnmResourceGroupName: vnmRg.name
    vnmName: vnm.outputs.networkManagerName
  }
}

module vnetHub 'modules/network/virtualNetwork.bicep' = {
  name: 'deploy-vnet-hub'
  scope: networkRg
  params: {
    location: location
    vnetName: vnetHubName
    vnmResourceGroupName: vnmRg.name
    vnmName: vnm.outputs.networkManagerName
    ipamPoolName: hubPool.outputs.ipamPoolName
  }
}

module vnetSpoke 'modules/network/virtualNetwork.bicep' = {
  name: 'deploy-spoke'
  scope: networkRg
  params: {
    location: location
    vnetName: vnetSpokeName
    vnmResourceGroupName: vnmRg.name
    vnmName: vnm.outputs.networkManagerName
    ipamPoolName: lzPool.outputs.ipamPoolName
    tags: {
      '_autojoin-networkgroup': 'true'
    }
  }
}

// define a connectivity configuration for the hub and spoke topology
module hubSpokeConfig 'modules/network/connectivityConfiguration.bicep' = {
  name: 'hub-spoke-config'
  scope: vnmRg
  params: {
    vnmName: vnm.outputs.networkManagerName
    vnmNetworkGroupName: vnm.outputs.networkGroupName
    vnetHubName: vnetHub.outputs.vnetName
    vnetResourceGroupName: networkRg.name
    useHubGateway: false
  }
}
