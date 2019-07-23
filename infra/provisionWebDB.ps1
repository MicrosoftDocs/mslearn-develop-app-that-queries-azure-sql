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
    $webAppSku,

    [Parameter(Mandatory = $True)]
    [string]
    $releaseDirectory,

    [Parameter(Mandatory = $True)]
    [string]
    $webStorageAccountName,

    [Parameter(Mandatory = $True)]
    [string]
    $webStorageAccountRegion,

    [Parameter(Mandatory = $True)]
    [string]
    $webStorageAccountSku,

    [Parameter(Mandatory = $True)]
    [string]
    $storageContainerName
)

function Upload-DefaultData {
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $databaseServerName,

        [Parameter(Mandatory = $True)]
        [string]
        $databaseName,

        [Parameter(Mandatory = $True)]
        [string]
        $databaseUser,

        [Parameter(Mandatory = $True)]
        [string]
        $databasePassword,

        [Parameter(Mandatory = $True)]
        [string]
        $storageAccountName,

        [Parameter(Mandatory = $True)]
        [string]
        $containerAndFile,

        [Parameter(Mandatory = $True)]
        [string]
        $dbTable
    )
    Write-Output "Uploading data for $dbTable..."
    Write-Output "creating database master key..."
    try {
        Invoke-Sqlcmd `
            -ConnectionString "Server=tcp:$($databaseServerName).database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$databaseUser;Password=$databasePassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
            -Query "CREATE MASTER KEY ENCRYPTION BY PASSWORD = '23987hxJ#KL95234nl0zBe'" 
    }
    catch {
        Write-Output "Master Key already exists"
    }
    Write-Output "Done creating database master key"
    
    Write-Output "creating database scoped credential..."
    try {
        Invoke-Sqlcmd `
            -ConnectionString "Server=tcp:$($databaseServerName).database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$databaseUser;Password=$databasePassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
            -Query "CREATE DATABASE SCOPED CREDENTIAL UploadDefaultData WITH IDENTITY = 'SHARED ACCESS SIGNATURE', SECRET = 'DyGv1v7cAtA=='" 
    }
    catch {
        Write-Output "scoped credential already exists"
    }
    Write-Output "Done creating database scoped credential"


    Write-Output "creating external data source..."
    try {
        Invoke-Sqlcmd `
            -ConnectionString "Server=tcp:$($databaseServerName).database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$databaseUser;Password=$databasePassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
            -Query "Drop External Data Source MyCourses"
    }
    catch {
        Write-Output "MyCourses does not exists in the DB"
    }
    Invoke-Sqlcmd `
        -ConnectionString "Server=tcp:$($databaseServerName).database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$databaseUser;Password=$databasePassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
        -Query "CREATE EXTERNAL DATA SOURCE MyCourses WITH  (TYPE = BLOB_STORAGE, LOCATION = 'https://$storageAccountName.blob.core.windows.net', CREDENTIAL = UploadDefaultData );"
    Write-Output "Done creating database external data source"
    
    # Write-Output "selecting openrowset..."
    # Invoke-Sqlcmd `
    #     -ConnectionString "Server=tcp:$($databaseServerName).database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$databaseUser;Password=$databasePassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
    #     -Query "SELECT * FROM OPENROWSET(BULK '$containerAndFile', DATA_SOURCE = 'MyExternalSource', SINGLE_CLOB) AS DataFile;"
    # Write-Output "Done selecitn openrowset"

    Write-Output "bulk inserting $dbTable..."
    Invoke-Sqlcmd `
        -ConnectionString "Server=tcp:$($databaseServerName).database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$databaseUser;Password=$databasePassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
        -Query "BULK INSERT $dbTable FROM '$containerAndFile' WITH (DATA_SOURCE = 'MyExternalSource', FORMAT = 'CSV', FirstRow=2);"
    Write-Output "Done Bulk inserting $dbTable"


}

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

# Create a resource group
#
Write-Output "Creating resource group..."
az group create `
    --name $resourceGroupName `
    --location $location
Write-Output "Done creating resource group"

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
    --capacity $dbCapacity `
    --zone-redundant $dbZoneRedundant
}
catch {
    Write-Output "sql db already exists"
}
Write-Output "Done creating sql db"

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
    --settings connectionString="Server=tcp:$($servername).database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Output "Done setting connection string"

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

# this creates a storage account for our back end azure application insight to use
# 
Write-Output "create a storage account for application insight..."
az storage account create `
    --name $webStorageAccountName `
    --location $webStorageAccountRegion `
    --resource-group $resourceGroupName `
    --sku $webStorageAccountSku
Write-Output "done creating storage account for application insight"
Write-Output ""

# Write-Output "loading data for courses..."
# Invoke-Sqlcmd `
# -ConnectionString "Server=tcp:$($servername).database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
# -Query "IF NOT EXISTS (SELECT * FROM Courses) BULK INSERT Courses FROM 'D:\a\r1\a\_LearnDB-ASP.NET Core-CI\drop\courses.csv' WITH (FORMAT = 'CSV', FIRSTROW=2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');" 
# Write-Output "done loading data"

#bcp "$dbName.dbo.courses" in "D:\a\r1\a\_LearnDB-ASP.NET Core-CI\drop\courses.csv" -S "$servername.database.windows.net" -U abel -P g83P@BxDXma700000 -F 2

# Write-Output "loading data for courses..."
# $sqlConnection = new-object ('System.Data.SqlClient.SqlConnection') "Server=tcp:abellearndbserver1.database.windows.net,1433;Initial Catalog=learndb;Persist Security Info=False;User ID=abel;Password=g83P@BxDXma700000;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
# #$serverConnection =  new-object ('Microsoft.SqlServer.Management.Common.ServerConnection') $sqlConnection
# $server = new-object ('Microsoft.SqlServer.Management.Smo.Server') #$serverConnection
# $db = $server.Databases["learndb"]
# $table = $db.Tables["Courses"]
# ,(Import-Csv -Path "D:\a\r1\a\_LearnDB-ASP.NETCore-CI\drop\courses.csv" -Header "ID","Course") | Write-SqlTableData -InputObject $table
# Write-Output "done loading data for courses"

# # Write-Output "loading data for courses..."
# Invoke-Sqlcmd `
# -ConnectionString "Server=tcp:$($servername).database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" `
# -Query "BULK INSERT Courses FROM 'D:\a\r1\a\_LearnDB-ASP.NETCore-CI\drop\courses.csv' WITH (FORMAT = 'CSV', FIRSTROW=2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');" 
# Write-Output "done loading data"



# $SqlConnection = New-Object  -TypeName System.Data.SqlClient.SqlConnection
# $SqlConnection.ConnectionString = "Server=tcp:$($servername).database.windows.net,1433;Initial Catalog=$dbName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
# $SqlCmd = New-Object  -TypeName System.Data.SqlClient.SqlCommand
# $SqlCmd.CommandText = $query
# $SqlCmd.Connection = $SqlConnection
# $SqlAdapter = New-Object  -TypeName System.Data.SqlClient.SqlDataAdapter
# $SqlAdapter.SelectCommand = $SqlCmd
# $DataSet = New-Object  -TypeName System.Data.DataSet
# $nSet = $SqlAdapter.Fill($DataSet)
# $SqlConnection.Close()
# $Tables = $DataSet.Tables


# Write-Output "installing sql server command line tools via chocolatey..."
# cinst sqlserver-cmdlineutils
# Write-Output "done installing sql server command line tools"

# Write-Output "refreshing environment..."
# refreshenv
# Write-Output "done refreshing environment"

# Create storage account container
#
Write-Output "Creating storage container for uploading data..."
az storage container create `
    --name $storageContainerName `
    --public-access container `
    --account-name $webStorageAccountName
Write-Output "Done creating data for uploading data"

#region Upload data files to storage
# Upload data files to storage
#
Write-Output "Getting key for storage..."
$keylist = $(az storage account keys list --account-name abellearndbstorage --resource-group abellearndbrg) | ConvertFrom-Json
$storageKey = $keylist[0].value
Write-Output "Finished getting key for storage"

Write-Output "Getting context for blob storage container..."
$Ctx = New-AzureStorageContext -StorageAccountName $webStorageAccountName -StorageAccountKey $storageKey
Write-Output "Done gettint context for blog storage container"

Write-Output "Upload the file using the context..."
Set-AzureStorageBlobContent `
    -File "D:\a\r1\a\_LearnDB-ASP.NETCore-CI\drop\courses.txt" `
    -Container $storageContainerName `
    -Blob "courses.txt" `
    -Context $Ctx `
    -Force

Set-AzureStorageBlobContent `
    -File "D:\a\r1\a\_LearnDB-ASP.NETCore-CI\drop\courses4.txt" `
    -Container $storageContainerName `
    -Blob "courses.txt" `
    -Context $Ctx `
    -Force

Set-AzureStorageBlobContent `
    -File "D:\a\r1\a\_LearnDB-ASP.NETCore-CI\drop\modules.txt" `
    -Container $storageContainerName `
    -Blob "modules.txt" `
    -Context $Ctx `
    -Force

Set-AzureStorageBlobContent `
    -File "D:\a\r1\a\_LearnDB-ASP.NETCore-CI\drop\studyplans.txt" `
    -Container $storageContainerName `
    -Blob "studyplans.txt" `
    -Context $Ctx `
    -Force
Write-Output "Done uploading the file"
#endregion

# Uploading default data for Courses
#
Write-Output "Checking data for Courses..."
$numRows=$(Invoke-Sqlcmd -ConnectionString "Server=tcp:abellearndbserver1.database.windows.net,1433;Initial Catalog=learndb;Persist Security Info=False;User ID=abel;Password=g83P@BxDXma700000;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" -Query "SELECT Count(*) FROM Courses")
if ($numRows.Column1 -eq 0) {
    Write-Output "No data for Courses, loading default data..."
    # # & "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\bcp" learndb.dbo.Courses in D:\a\r1\a\_LearnDB-ASP.NETCore-CI\drop\courses.txt -S abellearndbserver1.database.windows.net -U "abel@abellearndbserver1" -P "g83P@BxDXma700000" -q -c -t "," -F 2
    # & "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\bcp" learndb.dbo.Courses in D:\a\r1\a\_LearnDB-ASP.NETCore-CI\drop\courses.txt -S abellearndbserver1.database.windows.net -U "abel@abellearndbserver1" -P "g83P@BxDXma700000" -q -c -F 2 -f D:\a\r1\a\_LearnDB-ASP.NETCore-CI\drop\courses.fmt
    Upload-DefaultData `
        -databaseServerName $servername `
        -databaseName $dbName `
        -databaseUser $adminLogin `
        -databasePassword $adminPassword `
        -storageAccountName $webStorageAccountName `
        -containerAndFile $storageContainerName+"/courses4.txt" `
        -dbTable "Courses"

    Upload-DefaultData `
        -databaseServerName $servername `
        -databaseName $dbName `
        -databaseUser $adminLogin `
        -databasePassword $adminPassword `
        -storageAccountName $webStorageAccountName `
        -containerAndFile $storageContainerName+"/modules.txt" `
        -dbTable "Modules"

    Upload-DefaultData `
        -databaseServerName $servername `
        -databaseName $dbName `
        -databaseUser $adminLogin `
        -databasePassword $adminPassword `
        -storageAccountName $webStorageAccountName `
        -containerAndFile $storageContainerName+"/studyplans.txt" `
        -dbTable "Modules"
    Write-Output  "done loading data for $containerAndFile"
}

else {
    Write-Output "Data already exists for Courses"
}    
Write-Output "done checking data for Courses"


