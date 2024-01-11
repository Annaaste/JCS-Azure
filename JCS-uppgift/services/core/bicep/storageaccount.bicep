@description('Location for the resources to be deployed')
param location string

@description('Name prefix that will be used for all deployed resources')
@maxLength(25)
@minLength(3)
param namePrefix string
param workspaceId string

var coreStorageAccountName = replace('${namePrefix}st', '-', '')

resource archiveStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: coreStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'   
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Cool'
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
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
}

resource archiveStoragePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  name: 'default'
  parent: archiveStorageAccount
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'archive-rule'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToArchive: {
                  daysAfterModificationGreaterThan: 1
                  daysAfterLastTierChangeGreaterThan: 7
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
            }
          }
        }
      ]
    }
  }
}

resource blobDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${archiveStorageAccount.name}-diag'
  scope: archiveStorageAccount::blob
  properties: {
    workspaceId: workspaceId
    storageAccountId: archiveStorageAccount.id
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


output archiveStorageAccountId string = archiveStorageAccount.id
