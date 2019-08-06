CREATE TABLE [dbo].[Courses] (
    [CourseID]   INT          NOT NULL,
    [CourseName] VARCHAR (50) NOT NULL,
    [Teacher] VARCHAR(50) NULL, 
    PRIMARY KEY CLUSTERED ([CourseID] ASC)
);

