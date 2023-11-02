using System.Collections.Generic;
using System.Linq;
using Oracle.ManagedDataAccess.Client;

namespace GestionAutorizaciones.Infraestructure.Utils
{
    public static class DbUtils
    {
        public static string ParametersToString(OracleParameter[] parametros)
        {
            return string.Join(',', parametros.Select(p => ":" + p.ParameterName).ToArray());
        }
    }
}