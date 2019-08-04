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
    $adminLogin,

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
    $webAppSku,

    [Parameter(Mandatory = $True)]
    [string]
    $releaseDirectory,

    [Parameter(Mandatory = $True)]
    [string]
    $failoverName,

    [Parameter(Mandatory = $True)]
    [string]
    $partnerServerName,

    [Parameter(Mandatory = $True)]
    [string]
    $partnerServerLocation,

    [Parameter(Mandatory = $True)]
    [string]
    $trafficManagerProfileName,

    [Parameter(Mandatory = $True)]
    [string]
    $uniqueDNSName,

    [Parameter(Mandatory = $True)]
    [string]
    $node2Location
)

#region function to upload default data

# this function uploads default data to a table
#
function Upload-DefaultData {
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $dbServerName,

        [Parameter(Mandatory = $True)]
        [string]
        $dbId,

        [Parameter(Mandatory = $True)]
        [string]
        $userId,

        [Parameter(Mandatory = $True)]
        [string]
        $userPassword,

        [Parameter(Mandatory = $True)]
        [string]
        $releaseDirectoryName,

        [Parameter(Mandatory = $True)]
        [string]
        $uploadFile,

        [Parameter(Mandatory = $True)]
        [string]
        $tableName
    )
    Write-Output "Checking data for $tableName..."
    $numRows=$(Invoke-Sqlcmd -ConnectionString "Server=tcp:$dbServerName.database.windows.net,1433;Initial Catalog=$dbId;Persist Security Info=False;User ID=$userId;Password=$userPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
        -Query "SELECT Count(*) FROM $tableName" `
    )
    if ($numRows.Column1 -eq 0) {
        Write-Output "No data for $tableName, loading default data..."
        $fullDbName = $dbId + ".dbo." + $tableName
        $fullServerName = $dbServerName + ".database.windows.net"
        & "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\bcp" $fullDbName in $releaseDirectory\drop\data\$uploadFile -S $fullServerName -U $userId -P "$userPassword" -q -c -t "," -F 2
        Write-Output "done upload default data for $tableName"
    }
    else {
        Write-Output "Data already exists for $tableName"
    }    
    Write-Output "done checking data for $tableName"
}
#endregion



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



#region Create resource group

# Create a resource group
#
Write-Output "Creating resource group..."
az group create `
    --name $resourceGroupName `
    --location $location
Write-Output "Done creating resource group"
#endregion



#region Create Sql Server and database

# Create a logical sql server in the resource group
# 
Write-Output "Creating sql server..."
try {
    az sql server create `
    --name $servername `
    --resource-group $resourceGroupName `
    --location $location  `
    --admin-user $adminlogin `
    --admin-password $adminPassword
}
catch {
    Write-Output "SQL Server already exists"
}
Write-Output "Done creating sql server"

# Configure a firewall rule for the server
#
Write-Output "Creating firewall rule for sql server..."
try {
    az sql server firewall-rule create `
    --resource-group $resourceGroupName `
    --server $servername `
    -n AllowYourIp `
    --start-ip-address $startip `
    --end-ip-address $endip 
}
catch {
    Write-Output "firewall rule already exists"
}
Write-Output "Done creating firewall rule for sql server"

# Create a database in the server with zone redundancy as false
#
Write-Output "Create sql db $dbName..."
try {
    az sql db create `
    --resource-group $resourceGroupName `
    --server $servername `
    --name $dbName `
    --edition $dbEdition `
    --family $dbFamily `
    --zone-redundant $dbZoneRedundant `
	--capacity 1
}
catch {
    Write-Output "sql db already exists"
}
Write-Output "Done creating sql db"
#endregion



#region create app service

# create app service plan
#
Write-Output "creating app service plan..."
try {
    az appservice plan create `
    --name $("$webAppName" + "plan") `
    --resource-group $resourceGroupName `
    --sku $webAppSku
}
catch {
    Write-Output "app service already exists."
}
Write-Output "done creating app service plan"

Write-Output "creating web app..."
try {
    az webapp create `
    --name $webAppName `
    --plan $("$webAppName" + "plan") `
    --resource-group $resourceGroupName

}
catch {
    Write-Output "web app already exists"
}
Write-Output "done creating web app"

Write-Output "Setting connection string.."
az webapp config connection-string set `
    --name $webAppName `
    --connection-string-type "SQLAzure" `
    --resource-group $resourceGroupName `
    --settings DefaultConnection="Server=tcp:$($servername).database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Output "Done setting connection string"
#endregion



#region create db tables

# this block creates the initial tables if needed
#
Write-Output "creating db tables"
Invoke-Sqlcmd `
    -ConnectionString "Server=tcp:$($servername).database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
    -Query "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Courses' and xtype='U') CREATE TABLE Courses ( CourseID INT NOT NULL PRIMARY KEY, CourseName VARCHAR(50) NOT NULL );"

Invoke-Sqlcmd `
    -ConnectionString "Server=tcp:$($servername).database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
    -Query "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Modules' and xtype='U') CREATE TABLE Modules ( ModuleCode VARCHAR(5) NOT NULL PRIMARY KEY, ModuleTitle VARCHAR(50) NOT NULL );"

Invoke-Sqlcmd `
    -ConnectionString "Server=tcp:$($servername).database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
    -Query "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='StudyPlans' and xtype='U') CREATE TABLE StudyPlans ( CourseID INT NOT NULL, ModuleCode VARCHAR(5) NOT NULL, ModuleSequence INT NOT NULL, PRIMARY KEY ( CourseID, ModuleCode) );"

Write-Output "done creating db tables"
#endregion



#region upload default data to tables if needed

# Uploading default data for tables
#

Upload-DefaultData -dbServerName $servername -dbId $dbName -userId $adminLogin -userPassword $adminPassword -releaseDirectoryName $releaseDirectory -uploadFile courses.csv -tableName Courses
Upload-DefaultData -dbServerName $servername -dbId $dbName -userId $adminLogin -userPassword $adminPassword -releaseDirectoryName $releaseDirectory -uploadFile modules.csv -tableName Modules
Upload-DefaultData -dbServerName $servername -dbId $dbName -userId $adminLogin -userPassword $adminPassword -releaseDirectoryName $releaseDirectory -uploadFile studyplans.csv -tableName StudyPlans
#endregion

#region create db failover

# create failover group
#
# Create a logical sql server in the resource group
# 
Write-Output "Creating sql server for failover..."
try {
    az sql server create `
    --name $partnerServerName `
    --resource-group $resourceGroupName `
    --location $partnerServerLocation  `
    --admin-user $adminlogin `
    --admin-password $adminPassword
}
catch {
    Write-Output "Partner SQL Server already exists"
}
Write-Output "Done creating sql server"

# Configure a firewall rule for the server
#
Write-Output "Creating firewall rule for partner sql server..."
try {
    az sql server firewall-rule create `
    --resource-group $resourceGroupName `
    --server $partnerServerName `
    -n AllowYourIp `
    --start-ip-address $startip `
    --end-ip-address $endip 
}
catch {
    Write-Output "firewall rule already existsfor partner sql server"
}
Write-Output "Done creating firewall rule for partner sql server"

Write-Output "creating failover group..."
az sql failover-group create `
    --name $failoverName `
    --partner-server $partnerServerName `
    --resource-group $resourceGroupName `
    --server $servername `
    --failover-policy Automatic `
    --add-db $dbName
Write-Output "done creating failover group"

Write-Output "Setting connection string to failover..."
az webapp config connection-string set `
    --name $webAppName `
    --connection-string-type "SQLAzure" `
    --resource-group $resourceGroupName `
    --settings DefaultConnection="Server=tcp:$($failoverName).database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Output "Done setting connection string"
#endregion

#region traffic manager

# create traffic manager
#
Write-Output "creating traffic manager..."
az network traffic-manager profile create `
              --name $trafficManagerProfileName `
              --resource-group $resourceGroupName `
              --routing-method Priority `
              --path "/" `
              --protocol HTTPS `
              --unique-dns-name $uniqueDNSName `
              --ttl 30 `
              --port 80
Write-Output "done creating traffic manager"

Write-Output "creating app service plan for 2nd node..."
try {
    az appservice plan create `
    --name $("$webAppName" + "plan2") `
    --resource-group $resourceGroupName `
    --sku $webAppSku `
    --location $node2Location
}
catch {
    Write-Output "app service already exists for 2nd node."
}
Write-Output "done creating app service plan for 2nd node"

Write-Output "creating web app for 2nd node..."
try {
    az webapp create `
    --name $webAppName + "2" `
    --plan $("$webAppName" + "plan2") `
    --resource-group $resourceGroupName

}
catch {
    Write-Output "web app already exists for node 2"
}
Write-Output "done creating web app for node 2"

Write-Output "Setting connection string for node 2.."
az webapp config connection-string set `
    --name $webAppName + "2" `
    --connection-string-type "SQLAzure" `
    --resource-group $resourceGroupName `
    --settings DefaultConnection="Server=tcp:$failoverName.database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
Write-Output "Done setting connection string for node 2"

Write-Output "getting id for node 1 and 2..."
$node1 = $(az webapp show `
    --name $webAppName `
    --resource-group $resourceGroupName `
    | ConvertFrom-Json)
Write-Output "node 1: "
Write-Output $node1

$node2 = $(az webapp $webAppName + "2" `
--name coursesappwest `
--resource-group $resourceGroupName `
| ConvertFrom-Json)
Write-Output "node 2:"
Write-Output $node2
Write-Output "done getting id for node 2"

Write-Output "Add traffic manager endpoint for node 1..."
az network traffic-manager endpoint create `
    --name endpoint1 `
    --resource-group $resourceGroupName `
    --profile-name $trafficManagerProfileName `
    --type azureEndpoints `
    --target-resource-id $node1.id `
    --priority 1 `
    --endpoint-status Enabled
Write-Output "Done adding traffic manager endpoint for node 1"

Write-Output "Add traffic manager endpoint for node 2..."
az network traffic-manager endpoint create `
    --name endpoint2 `
    --resource-group $resourceGroupName `
    --profile-name $trafficManagerProfileName `
    --type azureEndpoints `
    --target-resource-id $node2.id `
    --priority 1 `
    --endpoint-status Enabled
Write-Output "Done adding traffic manager endpoint for node 2"
#endregion