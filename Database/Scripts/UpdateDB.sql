IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[Courses]') 
         AND name = 'Teacher'
)

ALTER TABLE dbo.Courses ADD Teacher VARCHAR(60) NULL;

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

GO