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

# setup backup for sql server
#
Write-Output "installing az.sql power shell..."
Install-Module -Name Az.Sql -AllowClobber -Scope CurrentUser -Force
Write-Output "done installing az.sql powershell"

Write-Output "creating short term backup plan..."
Set-AzSqlDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $resourceGroupName -ServerName $servername -DatabaseName $dbName -RetentionDays 35
Write-Output "done creating short term backup plan"

Write-Output "creating long term backup retention..."
ii.	Set-AzSqlDatabaseBackupLongTermRetentionPolicy -ServerName $servername -DatabaseName $dbName -ResourceGroupName $resourceGroupName -WeeklyRetention P12W
Write-Outut "done creating long term backup retention"

