param location string 
param timestamp string = utcNow('yyyyMMdd-HHmm')
param namePrefix string
param archiveStorageAccountId string
param workspaceId string
param ipCidrEnvVnet string
param dnsResourceGroupName string

resource manageId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'app-id'
  location: location
}

module vnet '../modules/vnet.bicep' = {
  name: '${namePrefix}-vnet'
  params:{
    location: location
    namePrefix: namePrefix
    ipPrefix: ipCidrEnvVnet
    subnetPrefix: cidrSubnet(ipCidrEnvVnet, 27, 0)
    storageAccountId: archiveStorageAccountId
    workspaceId: workspaceId
  }
}

module st 'storageaccount.bicep' = {
  name: 'JCS-st-${timestamp}'
  params: {
    namePrefix: namePrefix
    location: location
    archiveStorageAccountId: archiveStorageAccountId
    workspaceId: workspaceId
  }
}

module fapp 'function.bicep' = {
  name: 'JCS-func-${timestamp}'
  params: {
    namePrefix: namePrefix 
    location: location
    storageConnectionString: st.outputs.storageConnectionString
    storageAccountName: st.outputs.stName
    tableSFTPName: st.outputs.tabletsftppname
    manageId: manageId.id
    appInsightInstrumentationKey:appInsight.outputs.appInsightInstrumentationKey
  }
}

module rsv 'recoveryservicesvault.bicep' = {
  name: 'JCS-rsv-${timestamp}'
  params: {
    location: location
    archiveStorageAccountId: archiveStorageAccountId
    workspaceId: workspaceId
    namePrefix: namePrefix
  }
}

module appInsight 'applicationinsight.bicep' = {
  name: 'JCS-appInsight-${timestamp}'
  params: {
    location: location
    workspaceId: workspaceId
    namePrefix: namePrefix
  }
}

module localToRemotePeerings '../services/core/bicep/peeringSetup.bicep' = {
  scope: subscription()
  name: 'JCS-${'${namePrefix}-vnet'}-peerings'
  params: {
    localVnetId: vnet.outputs.vnetId
    remoteVnetIds: ['/subscriptions/3f03d422-196d-4c8c-aff9-8057f6d7f838/resourceGroups/jcs-core-mgmt-rg/providers/Microsoft.Network/virtualNetworks/jcs-core-mgmt-vnet']
  }
}

// Deploy private endpoints
module privateEndpoints '../modules/privateendpoints.bicep' = {
  name: 'peps-${timestamp}'
  params: {
    location: location
    endpoints: [
      {
        groupId: 'table'
        privateDnsZoneId: '/subscriptions/3f03d422-196d-4c8c-aff9-8057f6d7f838/resourceGroups/jcs-core-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.table.${environment().suffixes.storage}'
        privateLinkServiceId: st.outputs.stId
        privateEndpointName: '${split(st.outputs.stId, '/')[8]}-table-pep'
      }
      {
        groupId: 'blob'
        privateDnsZoneId: '/subscriptions/3f03d422-196d-4c8c-aff9-8057f6d7f838/resourceGroups/jcs-core-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.${environment().suffixes.storage}'
        privateLinkServiceId: st.outputs.stId
        privateEndpointName: '${split(st.outputs.stId, '/')[8]}-blob-pep'
      }
      {
        groupId: 'file'
        privateDnsZoneId: '/subscriptions/3f03d422-196d-4c8c-aff9-8057f6d7f838/resourceGroups/jcs-core-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.file.${environment().suffixes.storage}'
        privateLinkServiceId: st.outputs.stId
        privateEndpointName: '${split(st.outputs.stId, '/')[8]}-files-pep'
      }
      {
        groupId: 'sites'
        privateDnsZoneId: '/subscriptions/3f03d422-196d-4c8c-aff9-8057f6d7f838/resourceGroups/jcs-core-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net'
        privateLinkServiceId: fapp.outputs.functionId 
      }
      {
        groupId: 'sites'
        privateDnsZoneId: '/subscriptions/3f03d422-196d-4c8c-aff9-8057f6d7f838/resourceGroups/jcs-core-dns-rg/providers/Microsoft.Network/privateDnsZones/scm.privatelink.azurewebsites.net'
        privateLinkServiceId: fapp.outputs.functionId
        privateEndpointName: '${split(fapp.outputs.functionId, '/')[8]}-scm-pep'
      }
      {
        groupId: 'AzureBackup'
        privateDnsZoneId: '/subscriptions/3f03d422-196d-4c8c-aff9-8057f6d7f838/resourceGroups/jcs-core-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.sdc.backup.windowsazure.com'
        privateLinkServiceId: rsv.outputs.rsvId
      }
    ]
    subnetId: vnet.outputs.subnetId
  }
}

resource dnsRg 'Microsoft.Resources/resourceGroups@2023-07-01' existing =  {
  name: dnsResourceGroupName
  scope: subscription()
}

module dnsZones '../services/core/bicep/dnszones.bicep' = {
  name: 'dnszones'
  scope: dnsRg 
}
// Deploy Vnet Links
module privateDnsZoneLinkEnv 'virtualnetworkLinks.bicep' = {
  name: 'vnetLinkEnv-${timestamp}'
  dependsOn:[localToRemotePeerings]
  scope: dnsRg
  params: {
    privateDnsZoneIds: dnsZones.outputs.privateDnsZoneIds
    vnetId: vnet.outputs.vnetId
  }
}

// Deploy RSV protection container
module rsvProtectionContainer 'rsvbackupcontainer.bicep' = {
  name: 'rsv-container-${timestamp}' 
  dependsOn:[privateEndpoints]
  params: {
    rsvId: rsv.outputs.rsvId
    stId: st.outputs.stId
  }
}

resource vnetEnv 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: '${namePrefix}-vnet'
}

resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vnet-diag'
  scope: vnetEnv
  dependsOn: [vnet]
  properties: {
    workspaceId: workspaceId
    storageAccountId: archiveStorageAccountId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}
