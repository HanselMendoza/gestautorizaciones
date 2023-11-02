using System;
using System.Data.SqlClient;
namespace GestionAutorizaciones.Application.Common.Utils
{
    public static class ApplicationUtils
    {
        public static string DatabaseUser => 
           new SqlConnectionStringBuilder(Environment.GetEnvironmentVariable("CONNECTION_STRING")).UserID;
    }
}