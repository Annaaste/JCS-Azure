targetScope = 'subscription'

param location string
param namePrefix string
param coreResourceGroupName string = '${namePrefix}-rg'
param mgmtResourceGroupName string = '${namePrefix}-mgmt-rg'
param dnsResourceGroupName string = '${namePrefix}-dns-rg'
param ipVnet object

param roleAssignmentUserPrincipalId string

@secure()
param vmAdminPassword string

param timestamp string = utcNow('yyyyMMdd-HHmm')

// Variables
var vmName = '${namePrefix}-mgmt-vm'
var vmAdminUserName = 'jcsUser'

resource coreRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: coreResourceGroupName
  location: location
}

resource mgmtRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: mgmtResourceGroupName
  location: location
}

resource dnsRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: dnsResourceGroupName
  location: location
}

module dnsZone 'dnszones.bicep' = {
  name: 'dnsZones-${timestamp}'
  scope: dnsRg
}

module mainCore 'main-core.bicep' = {
  name: 'mainCore-${timestamp}'
  scope: coreRg
  params: {
    location: coreRg.location
    namePrefix: namePrefix
    timestamp: timestamp
    ipCidrCoreVnet: ipVnet.core    
  }
}

module mainMgmt 'main-mgmt.bicep' = {
  name: 'mainMgmt-${timestamp}'
  scope: mgmtRg
  params: {
    location: mgmtRg.location
    namePrefix: namePrefix
    roleAssignmentUserPrincipalId: roleAssignmentUserPrincipalId
    vmName: vmName
    vmAdminUserName: vmAdminUserName
    vmAdminPassword: vmAdminPassword
    workspaceId: mainCore.outputs.workspaceId
    archivestorageAccountId: mainCore.outputs.archiveStorageAccountId
    ipCidrMgmtVnet: ipVnet.mgmt    
  }
}

module privateDnsZoneLinkCore 'virtualnetworkLinks.bicep' = { 
  name: 'vnetLinkCore-${timestamp}'
  dependsOn:[localToRemotePeerings]
  scope: dnsRg
  params: {
    privateDnsZoneIds: dnsZone.outputs.privateDnsZoneIds
    vnetId: mainCore.outputs.vnetId
  }
}

module privateDnsZoneLinkMgmt 'virtualnetworkLinks.bicep' = {
  name: 'vnetlinkMgmt-${timestamp}' 
  dependsOn:[localToRemotePeerings]
  scope: dnsRg
  params: {
    privateDnsZoneIds: dnsZone.outputs.privateDnsZoneIds 
    vnetId: mainMgmt.outputs.vnetId
  }
}

module localToRemotePeerings 'peeringSetup.bicep' = {
  scope: subscription()
  name: 'JCS-${'${namePrefix}-vnet'}-peerings'
  params: {
    localVnetId: mainCore.outputs.vnetId
    remoteVnetIds: [mainMgmt.outputs.vnetId]
  }
}
