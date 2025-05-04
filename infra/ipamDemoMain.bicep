targetScope = 'subscription'

var location = deployment().location
param vnetName1 string = 'vnet-1' 
param vnetName2 string = 'vnet-2'
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

// define a child pool for a landingzone
module lz1Pool 'modules/network/ipamPool.bicep' = {
  name: 'lz1Pool'
  scope: vnmRg
  params: {
    ipamPoolAddressPrefixes: [
      '10.100.0.0/16'
    ]
    ipamPoolDescription: 'Landing Zone 1 Pool'
    location: location
    ipamPoolName: 'lz-01-pool'
    vnmName: vnm.outputs.networkManagerName
    ipamParentPoolName: rootPool.outputs.ipamPoolName
  }
}

// define a child pool for a landingzone
module lz2Pool 'modules/network/ipamPool.bicep' = {
  name: 'lz2Pool'
  scope: vnmRg
  params: {
    ipamPoolAddressPrefixes: [
      '10.101.0.0/16'
    ]
    ipamPoolDescription: 'Landing Zone 2 Pool'
    location: location
    ipamPoolName: 'lz-02-pool'
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

module vnet1 'modules/network/virtualNetwork.bicep' = {
  name: 'deploy-vnet1'
  scope: networkRg
  params: {
    location: location
    vnetName: vnetName1
    vnmResourceGroupName: vnmRg.name
    vnmName: vnm.outputs.networkManagerName
    ipamPoolName: lz1Pool.outputs.ipamPoolName
  }
}

module vnet2 'modules/network/virtualNetwork.bicep' = {
  name: 'deploy-vnet2'
  scope: networkRg
  params: {
    location: location
    vnetName: vnetName2
    vnmResourceGroupName: vnmRg.name
    vnmName: vnm.outputs.networkManagerName
    ipamPoolName: lz1Pool.outputs.ipamPoolName
  }
}
