using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using GestionAutorizaciones.Application.Autorizaciones.Common;
using GestionAutorizaciones.Domain.Entities;
using GestionAutorizaciones.Infraestructure.Utils;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Oracle.ManagedDataAccess.Client;
using Oracle.ManagedDataAccess.Types;

namespace GestionAutorizaciones.Infraestructure.Repositories
{
    public class AutorizacionRepositorio : IAutorizacionRepositorio
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger _logger;

        public AutorizacionRepositorio(ApplicationDbContext context, ILogger<AutorizacionRepositorio> logger)
        {
            _context = context;
            _logger = logger;
        }
        public async Task<IEnumerable<Reclamacion>> ObtenerInformacionReclamaciones(int? ano, int? compania, int? ramo, long? secuencial, long? codigoPss)
        {

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_ANO", OracleDbType.Int32, ano, direction: ParameterDirection.Input),
                new OracleParameter("P_COMPANIA", OracleDbType.Int32, compania, direction: ParameterDirection.Input),
                new OracleParameter("P_RAMO", OracleDbType.Int32, ramo, direction: ParameterDirection.Input),
                new OracleParameter("P_SECUENCIAL", OracleDbType.Long, secuencial, direction: ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, direction: ParameterDirection.Input),
                new OracleParameter("P_INFO_REC", OracleDbType.RefCursor, direction: ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_INFO_RECLAMACION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = (await _context.Set<Reclamacion>()
                .FromSqlRaw($"begin { procName }; end;", parametros)
                .ToListAsync());

            var outResultadoParam = int.Parse(parametros[6].Value.ToString());
            var outMensajeParam = parametros[7].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel, 
            "begin AUTORIZACIONES.P_OBTENER_INFO_RECLAMACION(p_ano => {P_ANO}, p_compania => {P_COMPANIA}, p_ramo => {P_RAMO}, p_secuencial => {P_SECUENCIAL}, p_codigo_pss => {P_CODIGO_PSS}, p_info_rec => {P_INFO_REC}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            ano, compania, ramo, secuencial, codigoPss, (result != null ? "(data)" : "(no data)"), outResultadoParam, outMensajeParam);
            
            return result;
        }

        public async Task<(decimal montoArs, decimal montoAsegurado)> ValidarCoberturaMedicina(long numeroSesion, string codigoSimon, string descripcionMedicamento, int cantidad, decimal precio)
        {

            var pResultado = new OracleParameter("p_resultado", OracleDbType.Int32, direction: ParameterDirection.Output);
            var pMontoArs = new OracleParameter("p_monto_ars", OracleDbType.Double, ParameterDirection.Output);
            var pMontoAsegurado = new OracleParameter("p_monto_ase", OracleDbType.Double, ParameterDirection.Output);

            var parametros = new OracleParameter[]
            {
                new OracleParameter("p_numsession", OracleDbType.Int64, numeroSesion, direction: ParameterDirection.Input),
                new OracleParameter("p_codsimon", OracleDbType.Varchar2, codigoSimon, direction: ParameterDirection.Input),
                new OracleParameter("p_descipcion_med", OracleDbType.Varchar2, descripcionMedicamento, direction: ParameterDirection.Input),
                new OracleParameter("p_cantidad", OracleDbType.Int32, cantidad, direction: ParameterDirection.Input),
                new OracleParameter("p_precio", OracleDbType.Double, precio, direction: ParameterDirection.Input),
                pResultado,
                pMontoArs,
                pMontoAsegurado
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_VALIDATECOBERTURA_MED({paramNames})";
            await _context.Database.ExecuteSqlRawAsync($"BEGIN {procName}; END;", parametros);

            var montoArs = (OracleDecimal)pMontoArs.Value;
            var montoAsegurado = (OracleDecimal)pMontoAsegurado.Value;

            return (montoArs.Value, montoAsegurado.Value);
        }
    }
}