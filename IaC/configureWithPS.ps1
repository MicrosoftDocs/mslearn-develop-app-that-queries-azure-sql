# This is an IaC script to provision the web and database into azure
# for the ms-learn module for DB's
#
[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory = $True)]
    [string]
    $servername,

    [Parameter(Mandatory = $True)]
    [string]
    $dbName,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalSecret,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipal,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalTenantId
)


# Login to Azure
#
Write-Output "Logging into Azure with service principal..."
$passwd = ConvertTo-SecureString $servicePrincipalSecret -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential($servicePrincipal, $passwd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId $servicePrincipalTenantId
Write-Output "Done logging into Azure"

# setup backup for sql server
#
Write-Output "installing az.sql power shell..."
Install-Module -Name Az.Sql -AllowClobber -Scope CurrentUser -Force
Write-Output "done installing az.sql powershell"

Write-Output "creating backup plan..."
Set-AzSqlDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $resourceGroupName -ServerName $servername -DatabaseName $dbName -RetentionDays 35
Write-Output "done creating backup plan"


