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

-- This populates the Teacher column with data if none exists
IF NOT EXISTS (
	SELECT * 
	FROM [dbo].[Courses]
	WHERE Teacher IS NOT NULL
)
BEGIN
	UPDATE dbo.Courses
	
	   SET Teacher = 'Frieda Joseph'
	
	 WHERE CourseName = 'Computer Science';
	
	UPDATE dbo.Courses
	
	   SET Teacher = 'Lenore Wilder'
	
	 WHERE CourseName = 'Maths with Computing';
	
	UPDATE dbo.Courses
	
	   SET Teacher = 'Benita Cortez'
	
	 WHERE CourseName = 'Maths with Physics';
	
	UPDATE dbo.Courses
	
	   SET Teacher = 'Jodie Webb'
	
	 WHERE CourseName = 'Computer Science with Physics';
	
	UPDATE dbo.Courses
	
	   SET Teacher = 'Dominique Barton'
	
	 WHERE CourseName = 'Maths with Chemistry';
	
	UPDATE dbo.Courses
	
	   SET Teacher = 'Jolene FLetcher'
	
	 WHERE CourseName = 'Physics with Chemistry';
	
	UPDATE dbo.Courses
	
	   SET Teacher = 'Liza Greene'
	
	 WHERE CourseName = 'Maths';
	
	UPDATE dbo.Courses
	
	   SET Teacher = 'Cornelia Ellis'
	
	 WHERE CourseName = 'Physics';
	
	UPDATE dbo.Courses
	
	   SET Teacher = 'Mike Chambliss'
	
	 WHERE CourseName = 'Chemistry';
	
END
GO
