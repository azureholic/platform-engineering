param vnmName string
param location string
param ipamParentPoolName string = ''
param ipamPoolName string
param ipamPoolDescription string
param ipamPoolAddressPrefixes array

resource networkManager 'Microsoft.Network/networkManagers@2022-09-01' existing = {
  name: vnmName
}

resource ipamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = {
  name: ipamPoolName
  parent: networkManager
  location: location
  properties: {
    description: ipamPoolDescription
    addressPrefixes: ipamPoolAddressPrefixes
    parentPoolName: ipamParentPoolName
  }
}

output ipamPoolName string = ipamPool.name
output ipamPoolId string = ipamPool.id
