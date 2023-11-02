using System;
using Microsoft.Extensions.Logging;
namespace GestionAutorizaciones.Infraestructure.Utils
{
    public static class LoggerUtils
    {
        public static LogLevel LogLevelResultadoParam(int codigoResultado) =>
            codigoResultado == Decimal.Zero ? LogLevel.Information : LogLevel.Warning;
    }
}