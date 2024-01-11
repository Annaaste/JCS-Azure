param rsvId string
param stId string



resource protectionContainer 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2023-04-01' = {
  name: '${split(rsvId, '/')[8]}/Azure/storagecontainer;Storage;${split(stId, '/')[4]};${split(stId, '/')[8]}'
  properties: {
    containerType: 'StorageContainer'
    backupManagementType: 'AzureStorage'
    sourceResourceId: stId
  }
      

}


output rsvProtectionContainerId string = protectionContainer.id
