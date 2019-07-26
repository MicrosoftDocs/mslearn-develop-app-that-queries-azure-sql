using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CoursesWebApp.lib
{
    public class ConnectionString : IConnectionString
    {
        private IConfiguration _config;

        string IConnectionString.ConnectionString => _config.GetConnectionString("DefaultConnection");

        public ConnectionString(IConfiguration config)
        {
            _config = config;
        }
    }
}
