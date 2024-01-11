@description('Location for the resources to be deployed')
param location string

param namePrefix string
param archiveStorageAccountId string
param workspaceId string

@description('The admin username that will be used for the deployed VM')
param vmAdminUserName string

@description('The admin password that will be used for the deployed VM.')
@secure()
param vmAdminPassword string
param subnetId string


var vmName = replace('${namePrefix}-mgmt-vm', '-', '')
var nicName = '${namePrefix}-nic'
var pipName = '${namePrefix}-pip'


resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  properties:{
    hardwareProfile: {
       vmSize: 'Standard_B2s'
    }
    storageProfile: {
       osDisk: {
        createOption:  'FromImage'
         diskSizeGB: 127
         managedDisk: {
           storageAccountType: 'StandardSSD_LRS'
         }
         deleteOption: 'Delete'
       }
       imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition-hotpatch'
        version: 'latest'
       }
    }
     networkProfile: {
       networkInterfaces: [
         {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
         }
       ]
     }
      additionalCapabilities: {
         hibernationEnabled: false
      }
       osProfile: {
        adminUsername: vmAdminUserName
        adminPassword: vmAdminPassword
        computerName: vmName
         }

        diagnosticsProfile: {
          bootDiagnostics: {
            enabled: true
           }    
          } 
  }
  identity: {
     type: 'SystemAssigned'
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: pipName
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
     name: 'Standard'
  }
   
}

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
      name: 'vm-ipconfig1'
      properties: {
        primary: true
        publicIPAddress: {
          id: pip.id
          }
           
          subnet: {
            id: subnetId
          } 
                       
         }
         
       }
    ]
  }  
  
}

resource vmPipDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vm-pip-diag'
  scope: pip
  properties: {
    workspaceId: workspaceId
    storageAccountId: archiveStorageAccountId
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output vmName string = vmName
output vmId string = vm.id
output vmAdminUserName string = vmAdminUserName

