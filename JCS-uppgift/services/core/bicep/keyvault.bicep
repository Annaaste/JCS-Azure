param location string 
param namePrefix string
param workspaceId string
param archiveStorageAccountId string

@description('Roleassignment for KV')
param roleAssignmentUserPrincipalId string

@secure()
param vmAdminPassword string

var kvName = '${namePrefix}-mgmt-kv'
var KeyVaultSecretOfficerAssignment = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'


resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    enableRbacAuthorization: true
    enableSoftDelete: false
    publicNetworkAccess: 'disabled'
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
  }
  resource vmPasswordSecret 'secrets' = {
    name: 'JCS-VmPassword'
    properties: {
      value: vmAdminPassword
    }
  }
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, KeyVaultSecretOfficerAssignment, roleAssignmentUserPrincipalId)
  scope:kv
  properties: {
    principalId: roleAssignmentUserPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', KeyVaultSecretOfficerAssignment)
  }
}

resource keyvaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'kv-diag'
  scope: kv
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

output kvId string = kv.id
