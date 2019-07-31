-- this adds the column teacher to the courses table if it
-- does not exist
if not exists (
  select * 
  from   sys.columns 
  where  object_id = object_id('[dbo].[Courses]') 
         and name = 'teacher'
)
begin
    alter table dbo.courses add teacher varchar(50) null;
end
go

-- this populates the teacher column with data if none exists
if not exists (
	select * 
	from [dbo].[courses]
	where teacher is not null
)
begin
	update dbo.courses
	
	   set teacher = 'frieda joseph'
	
	 where coursename = 'computer science';
	
	update dbo.courses
	
	   set teacher = 'lenore wilder'
	
	 where coursename = 'maths with computing';
	
	update dbo.courses
	
	   set teacher = 'benita cortez'
	
	 where coursename = 'maths with physics';
	
	update dbo.courses
	
	   set teacher = 'jodie webb'
	
	 where coursename = 'computer science with physics';
	
	update dbo.courses
	
	   set teacher = 'dominique barton'
	
	 where coursename = 'maths with chemistry';
	
	update dbo.courses
	
	   set teacher = 'jolene fletcher'
	
	 where coursename = 'physics with chemistry';
	
	update dbo.courses
	
	   set teacher = 'liza greene'
	
	 where coursename = 'math';
	
	update dbo.courses
	
	   set teacher = 'cornelia ellis'
	
	 where coursename = 'physics';
	
	update dbo.courses
	
	   set teacher = 'mike chambliss'
	
	 where coursename = 'chemistry';
	
end
go
