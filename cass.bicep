@description('The location for the resources.')
param location string = 'swedencentral'

@description('The name of the Virtual Network.')
param vnetName string = 'Test555'

@description('The name of the subnet.')
param subnetName string = 'Test555'

@description('The initial Cassandra admin password.')
@secure()
param initialCassandraAdminPassword string

@description('The version of Cassandra.')
param cassandraVersion string = '4.0'

@description('The Cassandra cluster name.')
param clusterName string = 'TEST555'

@description('The Cassandra datacenter name.')
param dataCenterName string = 'dc1'

@description('The SKU for Cassandra nodes.')
param nodeSku string = 'Standard_D8s_v4'

@description('The number of nodes in the datacenter.')
param nodeCount int = 3

@description('Disk capacity in TB for each Cassandra node.')
param diskCapacity int = 1

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: [
            {
              name: 'cassandraDelegation'
              properties: {
                serviceName: 'Microsoft.CosmosDB/clusters'
              }
            }
          ]
        }
      }
    ]
  }
}

resource cassandraCluster 'Microsoft.DocumentDB/cassandraClusters@2023-04-15' = {
  name: clusterName
  location: location
  properties: {
    delegatedManagementSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    initialCassandraAdminPassword: initialCassandraAdminPassword
    cassandraVersion: cassandraVersion
  }
  dependsOn: [
    vnet
  ]
}

resource cassandraDataCenter 'Microsoft.DocumentDB/cassandraClusters/dataCenters@2023-04-15' = {
  parent: cassandraCluster
  name: dataCenterName
  properties: {
    delegatedSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    nodeCount: nodeCount
    sku: nodeSku
    diskCapacity: diskCapacity
  }
}

output vnetId string = vnet.id
output subnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
output cassandraClusterId string = cassandraCluster.id
output cassandraDataCenterId string = cassandraDataCenter.id
