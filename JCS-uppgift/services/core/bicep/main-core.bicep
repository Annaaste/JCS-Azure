param location string
param namePrefix string
param ipCidrCoreVnet string
param timestamp string = utcNow('yyyyMMdd-HHmm')


module log 'loganalyticsworkspaces.bicep' = {
  name: 'JCS-log-${timestamp}'
  params: {
    location: location
    namePrefix: namePrefix
  }
}

module vnet '../../../modules/vnet.bicep' = {
  name: 'JCS-vnet-${timestamp}'
  params: {
    location: location
    namePrefix: namePrefix
    ipPrefix: ipCidrCoreVnet
    subnetPrefix: cidrSubnet(ipCidrCoreVnet, 27, 0)
    storageAccountId: st.outputs.archiveStorageAccountId
    workspaceId: log.outputs.workspaceId 
  }
}

module st 'storageaccount.bicep' = {
  name: 'JCS-st-${timestamp}'
  params: {
    location: location
    namePrefix: namePrefix
    workspaceId: log.outputs.workspaceId
  }
}

module privateEndpoints '../../../modules/privateendpoints.bicep' = {
  name: 'peps-${timestamp}'
  params: {
    location: location
    endpoints: [
      {
        groupId: 'blob'
        privateDnsZoneId: '/subscriptions/3f03d422-196d-4c8c-aff9-8057f6d7f838/resourceGroups/jcs-core-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.${environment().suffixes.storage}'
        privateLinkServiceId: st.outputs.archiveStorageAccountId
      }
    ]
    subnetId: vnet.outputs.subnetId
  }
}

resource vnetCore 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: '${namePrefix}-vnet'
}

resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vnet-diag'
  scope: vnetCore
  dependsOn: [vnet]
  properties: {
    workspaceId: log.outputs.workspaceId
    storageAccountId: st.outputs.archiveStorageAccountId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}


output archiveStorageAccountId string = st.outputs.archiveStorageAccountId
output workspaceId string = log.outputs.workspaceId
output vnetId string = vnet.outputs.vnetId
