Write-Host "Retrieving cluster credentials"
az aks get-credentials --resource-group $env:AZURE_RESOURCE_GROUP --name $env:AZURE_AKS_CLUSTER_NAME