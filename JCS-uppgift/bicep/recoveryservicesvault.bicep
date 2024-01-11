param location string 
param archiveStorageAccountId string
param workspaceId string
param namePrefix string


var skuName = 'RS0'
var skuTier = 'Standard'
var rsvBName = '${namePrefix}-rsv-bp'
var rsvName = '${namePrefix}-rsv'

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-06-01' = {
  name: rsvName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
  }

   resource rsvBackupPolicies 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' =  {
    parent: recoveryServicesVault
    name: rsvBName
    properties: {
      backupManagementType: 'AzureStorage'
      workLoadType: 'AzureFileShare'
      schedulePolicy: {
        schedulePolicyType: 'SimpleSchedulePolicy'
        scheduleRunFrequency: 'Daily'
        scheduleRunTimes: [
          '2023-12-15T10:30:00Z'
        ]
        scheduleWeeklyFrequency: 0
      }
      retentionPolicy: {
        retentionPolicyType: 'LongTermRetentionPolicy'
        dailySchedule: {
          retentionTimes: [
            '2023-12-15T10:30:00Z'
          ]
          retentionDuration: {
            count: 14
            durationType: 'Days'
          }
        }
      }
      timeZone: 'UTC'
      protectedItemsCount: 1
    }
  }
 


resource recoveryDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'recovery-diag'
  scope: recoveryServicesVault
  properties: {
    workspaceId: workspaceId
    storageAccountId: archiveStorageAccountId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output rsvId string = recoveryServicesVault.id
