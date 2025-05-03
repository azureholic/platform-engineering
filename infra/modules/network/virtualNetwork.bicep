@description('location of the virtual network')
param location string
@description('The name of the virtual network')
param vnetName string
@description('The name of the resource group for virtual networks')
param vnmResourceGroupName string
@description('The name virtual network manager')
param vnmName string
@description('The name of the IPAM pool')
param ipamPoolName string

resource vnmRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: vnmResourceGroupName
  scope: subscription()
}

resource networkManager 'Microsoft.Network/networkManagers@2022-09-01' existing = {
  name: vnmName
  scope: vnmRg
}

resource ipamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' existing = {
  name: ipamPoolName
  parent: networkManager
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: {
    '_autojoin-networkgroup': 'true'
  }
  properties: {
    addressSpace: {
      ipamPoolPrefixAllocations: [
        {
          numberOfIpAddresses: '256'
          pool: {
            id: ipamPool.id
          }
        }
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          ipamPoolPrefixAllocations: [
            {
              numberOfIpAddresses: '16'
              pool: {
                id: ipamPool.id
              }
            }
          ]
        }
      }
    ]
  }
}
