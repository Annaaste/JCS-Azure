
param privateDnsZoneIds array

param vnetId string

var vnetName = split(vnetId, '/')[8]

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = [for (zone, i) in privateDnsZoneIds: {
  name: split(zone, '/')[8]
}]

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in privateDnsZoneIds: {
  name: '${vnetName}-link'
  parent: privateDnsZone[i]
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}]
