param location string = resourceGroup().location
param workspaceId string
param namePrefix string

var appInsightName = '${namePrefix}-app-log'

resource appInsight 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightName
  location:  location
  kind: 'web'
   properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: workspaceId
    IngestionMode: 'LogAnalytics'    
  }
}

//output appInsightId string = appInsight.id
output appInsightInstrumentationKey string = appInsight.properties.InstrumentationKey
output appInsightConnectionString string = appInsight.properties.ConnectionString
