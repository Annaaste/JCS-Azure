
param location string 
param storageConnectionString string
param manageId string
param appInsightInstrumentationKey string
param storageAccountName string
param tableSFTPName string
param namePrefix string

var appName = '${namePrefix}-func'

resource storageAccountExisting 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: split(split(storageConnectionString, ';')[1],'=')[1]
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'jcs-plan'
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
}
/*
      Function App with function that creates new fileshares

*/
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${manageId}':{}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightInstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'storageAccountName'
          value: storageAccountName
        }
        {  
          name: 'resourceGroupName'
          value: resourceGroup().name
        }
        {
          name: 'tableSFTPName'
          value: tableSFTPName
        }
      ]

      publicNetworkAccess: 'Enabled'
      scmIpSecurityRestrictions: [
        {
          action: 'Allow'
          description: 'AllowVM'
          ipAddress: '10.150.0.0/24'
          name: 'VMAllow'
          priority: 10
        }
      ]
      scmIpSecurityRestrictionsDefaultAction: 'Deny'
      functionAppScaleLimit: 3
      minTlsVersion: '1.2'
    }
  }
   resource httpLogger 'functions' = {
     name: 'CreateSftpContainer'
     properties: {
       config: {
         bindings: [
           {
             name: 'Request'
             type: 'httpTrigger'
             direction: 'in'
             authLevel: 'function'
             methods: [
               'post'
             ]
           }
           {
             name: 'Response'
             type: 'http'
             direction: 'out'
           }
         ]
       }
      files: {
       'run.ps1': loadTextContent('functions/loggerFunction/run.ps1')
       '../requirements.psd1':  loadTextContent('functions/loggerFunction/requirements.psd1')
      }
      language: 'powershell'
     }
   }
}


  resource httpTrigger 'Microsoft.Web/sites/functions@2022-09-01' = {
    name: 'CreateFileshare'
    parent: functionApp
    properties: {
      config: {
        bindings: [
          {
            name: 'Request'
            type: 'httpTrigger'
            direction: 'in'
            authLevel: 'function'
            methods: [
              'post'
            ]
          }
          {
            name: 'Response'
            type: 'http'
            direction: 'out'
          }
        ]
      }
     files: {
      'run.ps1': loadTextContent('functions/fileshareFunction/run.ps1')
     }
     language: 'powershell'
    }
  }


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  scope: storageAccountExisting
  properties: {
    principalId: functionApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
  }
}


output functionUrl string = functionApp.properties.defaultHostName
output functionId string = functionApp.id
