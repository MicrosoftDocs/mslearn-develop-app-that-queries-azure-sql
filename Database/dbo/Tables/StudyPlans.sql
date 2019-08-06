CREATE TABLE [dbo].[StudyPlans] (
    [CourseID]       INT         NOT NULL,
    [ModuleCode]     VARCHAR (5) NOT NULL,
    [ModuleSequence] INT         NOT NULL,
    PRIMARY KEY CLUSTERED ([CourseID] ASC, [ModuleCode] ASC)
);

