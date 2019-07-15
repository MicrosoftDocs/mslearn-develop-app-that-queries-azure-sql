# This is an IaC script to provision the web and database into azure
# for the ms-learn module for DB's
#
[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipal,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalSecret,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalTenantId,

    [Parameter(Mandatory = $True)]
    [string]
    $azureSubscriptionName,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory = $True)]
    [string]
    $location,

    [Parameter(Mandatory = $True)]
    [string]
    $adminlogin,

    [Parameter(Mandatory = $True)]
    [string]
    $adminPassword,

    [Parameter(Mandatory = $True)]
    [string]
    $servername,

    [Parameter(Mandatory = $True)]
    [string]
    $startip,

    [Parameter(Mandatory = $True)]
    [string]
    $endip,

    [Parameter(Mandatory = $True)]
    [string]
    $dbName,

    [Parameter(Mandatory = $True)]
    [string]
    $dbEdition,

    [Parameter(Mandatory = $True)]
    [string]
    $dbFamily,

    [Parameter(Mandatory = $True)]
    [string]
    $dbCapacity,

    [Parameter(Mandatory = $True)]
    [string]
    $dbZoneRedundant,

    [Parameter(Mandatory = $True)]
    [string]
    $webAppName,

    [Parameter(Mandatory = $True)]
    [string]
    $webAppSku

)


#region Login

# This logs in a service principal
#
Write-Output "Logging in to Azure with a service principal..."
az login `
    --service-principal `
    --username $servicePrincipal `
    --password $servicePrincipalSecret `
    --tenant $servicePrincipalTenantId
Write-Output "Done"
Write-Output ""

# This sets the subscription to the subscription I need all my apps to
# run in
#
Write-Output "Setting default azure subscription..."
az account set `
    --subscription "$azureSubscriptionName"
Write-Output "Done"
Write-Output ""
#endregion

function 1_Up {
    # Create a resource group
    Write-Output "Creating resource group..."
    az group create `
        --name $resourceGroupName `
        --location $location
    Write-Output "Done creating resource group"

    # Create a logical server in the resource group
    Write-Output "Creating sql server..."
    az sql server create `
        --name $servername `
        --resource-group $resourceGroupName `
        --location $location  `
        --admin-user $adminlogin `
        --admin-password $adminPassword
    Write-Output "Done creating sql server"

    # Configure a firewall rule for the server
    Write-Output "Creating firewall rule for sql server..."
    az sql server firewall-rule create `
        --resource-group $resourceGroupName `
        --server $servername `
        -n AllowYourIp `
        --start-ip-address $startip `
        --end-ip-address $endip `
    Write-Output "Done creating firewall rule for sql server"

    # Create a database in the server with zone redundancy as false
    Write-Output "Create sql db $dbName..."
    az sql db create `
        --resource-group $resourceGroupName `
        --server $servername `
        --name $dbName `
        --edition $dbEdition `
        --family $dbFamily `
        --capacity $dbCapacity `
        --zone-redundant $dbZoneRedundant
    Write-Output "Done creating sql db"
     
    # create app service plan
    #
    Write-Output "creating app service plan..."
    az appservice plan create `
        --name "$webAppName" + "plan" `
        --resource-group $resourceGroupName `
        --sku $webAppSku
    Write-Output "done creating app service plan"
    
    Write-Output "creating web app..."
    az webapp create `
        --name $webAppName `
        --plan "$webAppName" + "plan" `
        --resource-group $resourceGroupName
    Write-Output "done creating web app"
}

Install-Module -Name VersionInfrastructure -Force -Scope CurrentUser
Update-InfrastructureVersion `
    -infraToolsFunctionName "$Env:IaC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME" `
    -infraToolsTableName "$Env:IAC_INFRATABLENAME" `
    -deploymentStage "$Env:IAC_DEPLOYMENTSTAGE"