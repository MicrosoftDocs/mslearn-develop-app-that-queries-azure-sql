# setup backup for sql server
#
Write-Output "installing az.sql power shell..."
Install-Module -Name Az.Sql -AllowClobber -Scope CurrentUser -Force
Write-Output "done installing az.sql powershell"

Write-Output "creating backup plan..."
Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $resourceGroupName -InstanceName $servername -DatabaseName $dbName -RetentionDays 35
Write-Output "done creating backup plan"


