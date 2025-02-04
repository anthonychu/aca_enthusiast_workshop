var acrName = 'acrtechconnect${uniqueString(resourceGroup().id)}'
var acaEnvName = 'ace-techconnect'
var appName = 'app1'

resource env 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: acaEnvName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

resource app 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: appName
  location: resourceGroup().location
  properties: {
    configuration: {
      ingress: {
        external: true
      }
    }
    template: {
      containers: [
        {
          name: 'nginx'
          image: '${acr.properties.loginServer}/nginx:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    env
  ]
}


var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, acrPullRoleId, env.id)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: app.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
