@description('Location where the resources will be deployed')
param location string

@description('Name prefix that will be used for all deployed resources')
param namePrefix string
param ipPrefix string
param subnetPrefix string
param storageAccountId string
param workspaceId string

var nsgName = '${namePrefix}-nsg'
var vnetName = '${namePrefix}-vnet'
var subnetName = '${namePrefix}-snet'


resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules:loadJsonContent('nsgsecurityrules.json')
  }
}

resource nsgDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${nsg.name}-diag'
  scope: nsg
  properties: {
    workspaceId: workspaceId
    storageAccountId: storageAccountId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
       addressPrefixes: [
        ipPrefix
       ]
     
    }
    subnets: [
       {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsg.id
              properties: {
                
                }
              }
          }
       }
    ] 
  }  
} 




output subnetId string = vnet.properties.subnets[0].id
output vnetName string = vnet.name
output vnetId string = vnet.id
