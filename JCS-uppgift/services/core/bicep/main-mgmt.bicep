param location string 
param namePrefix string
param timestamp string = utcNow('yyyyMMdd-HHmm')
param vmName string
param archivestorageAccountId string
param workspaceId string
param roleAssignmentUserPrincipalId string
@secure()
param vmAdminPassword string
param vmAdminUserName string
param ipCidrMgmtVnet string


module vnet '../../../modules/vnet.bicep'= {
  name: 'JCS-mgmt-${timestamp}'
  params: {
    location: location
    namePrefix: '${namePrefix}-mgmt'
    ipPrefix: ipCidrMgmtVnet
    subnetPrefix: cidrSubnet(ipCidrMgmtVnet,27,0)
    storageAccountId: archivestorageAccountId
    workspaceId: workspaceId
  }
}

module kv 'keyvault.bicep' = {
  name: 'JCS-kv-${timestamp}'
  params: {
    namePrefix: namePrefix 
    location: location
    archiveStorageAccountId: archivestorageAccountId
    workspaceId: workspaceId
    roleAssignmentUserPrincipalId: roleAssignmentUserPrincipalId
    vmAdminPassword: vmAdminPassword
  }
}

module vm 'virtualmachine.bicep' = {
  name: '${vmName}-${timestamp}'
  params: {
    location:location
    namePrefix: namePrefix
    subnetId: vnet.outputs.subnetId
    vmAdminPassword: vmAdminPassword
    vmAdminUserName: vmAdminUserName 
    archiveStorageAccountId: archivestorageAccountId
    workspaceId: workspaceId
  }
}

module privateEndpoints '../../../modules/privateendpoints.bicep' = {
  name: 'peps-${timestamp}'
  params: {
    location: location
    endpoints: [
      {
        groupId: 'vault'
        privateDnsZoneId: '/subscriptions/3f03d422-196d-4c8c-aff9-8057f6d7f838/resourceGroups/jcs-core-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
        privateLinkServiceId: kv.outputs.kvId
      }
    ]
    subnetId: vnet.outputs.subnetId
  }
}

resource vnetMgmt 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: '${namePrefix}-mgmt-vnet'
}

resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vnet-diag'
  scope: vnetMgmt
  dependsOn: [vnet]
  properties: {
    workspaceId: workspaceId
    storageAccountId: archivestorageAccountId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}


output vnetId string = vnet.outputs.vnetId
