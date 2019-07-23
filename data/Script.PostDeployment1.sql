/*
Load default data script
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
    DROP EXTERNAL DATA SOURCE MyCourses
END TRY
BEGIN CATCH
    PRINT N'External Data Source MyCourses does not exist'
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

BULK INSERT Courses
FROM 'uploaddata/courses4.txt'
WITH (DATA_SOURCE = 'MyCourses',
      FORMAT = 'CSV',
      FirstRow=2);


