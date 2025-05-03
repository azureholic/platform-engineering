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
    ipamPoolName: vnm.outputs.ipamPoolName1
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
    ipamPoolName: vnm.outputs.ipamPoolName1
  }
}
