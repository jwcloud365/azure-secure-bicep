/*
  Resource Group Module
  
  This module creates the resource group that will contain all other resources.
*/

targetScope = 'subscription'

// ------------- Parameters -------------
@description('The name of the resource group')
param resourceGroupName string

@description('The Azure region for the resource group')
param location string

@description('Tags to apply to the resource group')
param tags object = {}

// ------------- Resources -------------
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ------------- Outputs -------------
output resourceGroupId string = rg.id
output resourceGroupName string = rg.name
