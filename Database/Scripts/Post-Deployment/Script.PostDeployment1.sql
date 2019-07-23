/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
BEGIN TRY
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = '23987hxJ#KL95234nl0zBe';
END TRY
BEGIN CATCH
	PRINT N'Master key already exists'; 
END CATCH

BEGIN TRY
	CREATE DATABASE SCOPED CREDENTIAL UploadDefaultDataCred
	WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
	SECRET = 'DyGv1v7cAtA==';
END TRY
BEGIN CATCH
    PRINT N'Database credential to storage already exists';
END CATCH

BEGIN TRY
	CREATE EXTERNAL DATA SOURCE MyCourses
    WITH  (
        TYPE = BLOB_STORAGE,
        LOCATION = 'https://abellearndbstorage.blob.core.windows.net', 
        CREDENTIAL = UploadDefaultDataCred
    );
END TRY
BEGIN CATCH
    PRINT N'MyCourses external data source already exists';
END CATCH
GO;

BULK INSERT Courses
FROM 'uploaddata/courses4.txt'
WITH (DATA_SOURCE = 'MyCourses',
      FORMAT = 'CSV',
      FirstRow=2);


