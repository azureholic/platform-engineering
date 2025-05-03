@description('Name of the virtual network manager network group')
param networkGroupName string
@description('The name of the resource group containing the virtual networks')
param vnetResourceGroupName string
@description('The name of the resource group containing the network manager')
param vnmResourceGroupName string 
@description('The name of the virtual network manager')
param vnmName string 

targetScope = 'subscription'

resource networkManager 'Microsoft.Network/networkManagers@2022-09-01' existing = {
  name: vnmName
  scope: resourceGroup(vnmResourceGroupName)
}

resource networkGroup 'Microsoft.Network/networkManagers/networkGroups@2022-09-01' existing = {
  name: networkGroupName
  parent: networkManager
}

@description('This is a Policy definition for dynamic group membership')
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: uniqueString(networkGroup.id)
  properties: {
    description: 'AVNM - Dynamic group membership Policy'
    displayName: 'AVNM - Dynamic group membership Policy'
    mode: 'Microsoft.Network.Data'
    policyRule: {
      if: {
        allof: [
          {
            field: 'type'
            equals: 'Microsoft.Network/virtualNetworks'
          }
          {
            // virtual networks must have a tag where the key is '_autojoin-networkgroup'
            field: 'tags[_autojoin-networkgroup]'
            exists: true
          }
          {
            // virtual network ids must include this sample's resource group ID - limiting the chance that dynamic membership impacts other vnets in your subscriptions
            field: 'id'
            like: '${subscription().id}/resourceGroups/${vnetResourceGroupName}/*'
          }
        ]
      }
      then: {
        // 'addToNetworkGroup' is a special effect used by AVNM network groups
        effect: 'addToNetworkGroup'
        details: {
          networkGroupId: networkGroup.id
        }
      }
    }
  }
}

@description('This is a Policy assignment for dynamic group membership')
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: uniqueString(networkGroup.id)
  properties: {
    displayName: 'AVNM - Add virtual networks to network group'
    policyDefinitionId: policyDefinition.id
    enforcementMode: 'Default'
  }
}
