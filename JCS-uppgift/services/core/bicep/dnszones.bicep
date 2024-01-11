param dnsZoneNames array = [
  'privatelink.vaultcore.azure.net'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.sdc.backup.windowsazure.com'
  'privatelink.azurewebsites.net'
  'scm.privatelink.azurewebsites.net'
]

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for (zone, i) in dnsZoneNames: {
  name: zone
  location: 'global'
}]


 resource privateDnsZoneSoa 'Microsoft.Network/privateDnsZones/SOA@2020-06-01' existing = [for (zone, i) in dnsZoneNames: {
   name: '@'
   parent: privateDnsZone[i]
 }]

 resource dnsZoneLock 'Microsoft.Authorization/locks@2016-09-01' = [for (zone, i) in dnsZoneNames:{
   name: 'dnsLock'
   scope: privateDnsZoneSoa[i]
   properties:{
     level: 'CanNotDelete'
     notes: 'Zone should not be deleted.'
   }
 }
 ]

// Outputs
output privateDnsZoneIds array = [for (zone, i) in dnsZoneNames: privateDnsZone[i].id ]


