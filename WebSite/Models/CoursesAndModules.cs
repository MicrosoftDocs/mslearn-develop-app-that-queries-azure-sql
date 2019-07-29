namespace CoursesWebApp.Models
{
    public class CoursesAndModules
    {
        public string CourseName { get; }
        public string ModuleTitle { get; }
        public int Sequence { get; }


        public CoursesAndModules(string courseName, string moduleTitle, int sequence)
        {
            this.CourseName = courseName;
            this.ModuleTitle = moduleTitle;
            this.Sequence = sequence;
        }
    }
}
