using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CoursesWebApp.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Configuration;

namespace CoursesWebApp.Pages
{
    public class CoursesAndModulesModel : PageModel
    {
        private IConfiguration _configuration;
        private DataAccessController _dac;

        public List<CoursesAndModules> CoursesAndModules;

        public CoursesAndModulesModel (IConfiguration configuration)
        {
            _configuration = configuration;
            _dac = new DataAccessController(_configuration);
        }

        public void OnGet()
        {
            CoursesAndModules = _dac.GetAllCoursesAndModules().ToList();
        }
    }
}