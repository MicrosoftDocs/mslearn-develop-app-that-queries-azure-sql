namespace CoursesWebApp.Models
{
    public class CoursesAndModules
    {
        public string CourseName { get; }
        public string ModuleTitle { get; }
        public int Sequence { get; }
        public string Teacher { get; set; }


        public CoursesAndModules(string courseName, string moduleTitle, string teacher, int sequence)
        {
            this.CourseName = courseName;
            this.ModuleTitle = moduleTitle;
            this.Sequence = sequence;
            this.Teacher = teacher;
        }
    }
}
