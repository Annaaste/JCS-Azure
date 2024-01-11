param location string
param endpoints array
param subnetId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = [for (endpoint, i) in endpoints: {
  name: endpoint.?privateEndpointName ?? '${split(endpoint.privateLinkServiceId, '/')[8]}-pep'
  location: location   
  properties: {
    privateLinkServiceConnections: [
      {
        name: endpoint.?privateEndpointName ?? '${split(endpoint.privateLinkServiceId, '/')[8]}-pep'
        properties: {
          privateLinkServiceId: endpoint.privateLinkServiceId
          groupIds: [
            endpoint.groupId
          ]        
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }  
}]

resource dnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = [for (endpoint, i) in endpoints: {
  name: 'default'
  parent: privateEndpoint[i]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: endpoint.privateDnsZoneId
        }
      }
    ]
  }
}]
