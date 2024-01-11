targetScope = 'subscription'

@description('Resource ID of the local VNET')
param localVnetId string

@description('Resource IDs of the remote VNETs')
param remoteVnetIds array

param timestamp string = utcNow('yyyyMMdd-HHmm')

module localToRemotePeerings 'peeringTemplate.bicep' = {
  scope: resourceGroup(split(localVnetId, '/')[4])
  name: 'JCS-local-to-remote-peerings-${timestamp}'
  params: {
    localVnetId: localVnetId
    remoteVnetIds: remoteVnetIds
  }
}

module RemoteToLocalPeerings 'peeringTemplate.bicep' = [for (remoteVnet, i) in remoteVnetIds: {
  scope: resourceGroup(split(remoteVnet, '/')[4])
  name: 'JCS-${split(remoteVnet, '/')[8]}-peering-to-local-${timestamp}'
  params: {
    localVnetId: remoteVnet
    remoteVnetIds: [localVnetId]
  }
}]
