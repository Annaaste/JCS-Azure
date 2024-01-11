
@description('Resource ID of the local VNET')
param localVnetId string

@description('Resource IDs of the remote VNETs')
param remoteVnetIds array

@description('If gateway links can be used in remote virtual networking to link to this virtual network.')
param allowGatewayTransit bool = false

@description('If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true')
param useRemoteGateways bool = false

// Get existing local vNET
resource vnetLocal 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: split(localVnetId, '/')[8]
}

// Deploy VNET peering
resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = [for (remoteVnet, i) in remoteVnetIds: {
  name: '${split(localVnetId, '/')[8]}-to-${split(remoteVnet, '/')[8]}'
  parent: vnetLocal
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnet
    }
  }
}]

// Outputs
output vnetPeeringIds array = [for (remoteVnet, i) in remoteVnetIds: vnetPeering[i].id ]
