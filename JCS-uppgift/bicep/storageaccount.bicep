param location string = resourceGroup().location
param archiveStorageAccountId string
param workspaceId string
param namePrefix string

var stName = replace('${namePrefix}st', '-', '')


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: stName
  location: location
  sku: {
    name: 'Standard_LRS'   
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    isSftpEnabled: true
    isHnsEnabled: true
  }
  resource blob 'blobServices' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: [
          {
            allowedHeaders: [
              '*'
            ]
            allowedMethods: [
              'POST'
              'PUT'
              'GET'
            ]
            allowedOrigins: [
              '*'
            ]
            exposedHeaders: [
              '*'
            ]
            maxAgeInSeconds: 200
          }
        ]
      }
    }
  }
  resource tables 'tableServices' = {
    name: 'default'
    properties: { 
     cors: {
      corsRules: [
         {
          allowedHeaders: [
             '*'
          ]
           allowedMethods: [
            'POST'
            'PUT'
            'GET'

           ]
            allowedOrigins: [
              '*'
            ]
            exposedHeaders: [
              '*'
            ]
            maxAgeInSeconds: 200
         }
      ]
     }    
    }
    resource table 'tables' = {
      name: 'FileshareOrders'
    }
    resource tableSFTP 'tables' = {
      name: 'SFTPOrders'
    }
  }

  resource fileShares 'fileServices' =  {
    name: 'default' 
   properties: {
     shareDeleteRetentionPolicy: {
        enabled: true
       days: 14 
     } 
   } 
  }

  resource queues 'queueServices' existing = {
    name: 'default'
  }
}

resource blobDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccount.name}-diag'
  scope: storageAccount::blob
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

resource tableDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'table-diag'
  scope: storageAccount::tables
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

resource fileSharesDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'fileshare-diag'
  scope: storageAccount::fileShares
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

resource queueDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'queues-diag'
  scope: storageAccount::queues
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


output rgname string = resourceGroup().name
output storageConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
output stId string = storageAccount.id
output stName string = storageAccount.name
output tablehttpname string = storageAccount::tables::table.name
output tabletsftppname string = storageAccount::tables::tableSFTP.name
