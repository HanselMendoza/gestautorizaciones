using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using GestionAutorizaciones.Application.Precertificaciones.Common;
using GestionAutorizaciones.Domain.Entities;
using GestionAutorizaciones.Infraestructure.Utils;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Oracle.ManagedDataAccess.Client;

namespace GestionAutorizaciones.Infraestructure.Repositories
{
    public class PrecertificacionRepositorio : IPrecertificacionRepositorio
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger _logger;
        public PrecertificacionRepositorio(ApplicationDbContext context, ILogger<PrecertificacionRepositorio> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<ActivacionPrecertificacion> ActivarPrecertificacion(long numeroSesion, long numeroPrecertificacion, string usuarioRegistra)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("p_numsession", OracleDbType.Long, numeroSesion, ParameterDirection.Input),
                new OracleParameter("p_instr1", OracleDbType.Varchar2, Convert.ToString(numeroPrecertificacion), ParameterDirection.Input),
                new OracleParameter("p_user_register", OracleDbType.Varchar2, usuarioRegistra, direction: ParameterDirection.Input),
                new OracleParameter("p_outstr1", OracleDbType.Varchar2, 200 , null, ParameterDirection.Output),
                new OracleParameter("p_outstr2", OracleDbType.Varchar2, 200 , null, ParameterDirection.Output),
                new OracleParameter("p_outnum1", OracleDbType.Int32, ParameterDirection.Output),

            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_ACTIVAR_PRECERTIFICACION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outNumeroAutorizacion = Convert.ToString(parametros[3].Value);
            var outTipoAutorizacion = Convert.ToString(parametros[4].Value);
            var outPrecertificacionActivada = Convert.ToString(parametros[5].Value);

            _logger.Log(LogLevel.Information,
            "begin AUTORIZACIONES.P_ACTIVAR_PRECERTIFICACION(p_numsession => {p_numsession}, p_instr1 => {p_instr1}, p_user_register => {p_user_register}, p_outstr1 => {p_outstr1}, p_outstr2 => {p_outstr2}, p_outnum1 => {p_outnum1}); end;",
            numeroSesion, numeroPrecertificacion, usuarioRegistra, outNumeroAutorizacion, outTipoAutorizacion, outPrecertificacionActivada);

            return new ActivacionPrecertificacion
            {
                NumeroAutorizacion = outNumeroAutorizacion,
                TipoAutorizacion = outTipoAutorizacion,
                CodigoValidacion = int.Parse(outPrecertificacionActivada)
            };
        }

        public async Task<IEnumerable<Precertificacion>> ObtenerDatosPrecertificacion(string tipoPss, long codigoPss, int compania, long numeroPrecertificacion)
        {

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, tipoPss, ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_COMPANIA", OracleDbType.Int32, compania, ParameterDirection.Input),
                new OracleParameter("P_NUM_PRECERT", OracleDbType.Long, numeroPrecertificacion, ParameterDirection.Input),
                new OracleParameter("P_PRECERTIFICACION", OracleDbType.RefCursor, direction: ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_DATOS_PRECERTIFICACION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = (await _context.Set<Precertificacion>()
                .FromSqlRaw($"begin {procName}; end;", parametros)
                .ToListAsync());

            var outResultadoParam = int.Parse(parametros[5].Value.ToString());
            var outMensajeParam = parametros[6].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_DATOS_PRECERTIFICACION(p_tipo_pss => {P_TIPO_PSS}, p_codigo_pss => {P_CODIGO_PSS}, p_compania => {P_COMPANIA}, p_num_precert => {P_NUM_PRECERT}, p_precertificacion => {P_PRECERTIFICACION}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            tipoPss, codigoPss, compania, numeroPrecertificacion, (result != null ? "(data)" : "(no data)"), outResultadoParam, outMensajeParam);

            return result;
        }

        public async Task<ValidacionPrecertificacion> ValidarPrecertificacion(string tipoPss, long? codigoPss, int? compania, long? numeroPrecertificacion)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, tipoPss, ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_COMPANIA", OracleDbType.Int32, compania, ParameterDirection.Input),
                new OracleParameter("P_NUM_PRECERT", OracleDbType.Long, numeroPrecertificacion, ParameterDirection.InputOutput),
                new OracleParameter("P_AUTORIZA", OracleDbType.Varchar2, 200 , null, ParameterDirection.Output),
                new OracleParameter("P_ORIGEN", OracleDbType.Varchar2, 200 , null, ParameterDirection.Output),
                new OracleParameter("P_OUTNUM", OracleDbType.Int32, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)

            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_VALIDA_PRECERTIFICACION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outCodigoValidacion = Convert.ToString(parametros[6].Value);
            var outResultado = int.Parse(parametros[7].Value.ToString());
            var outTipoAutorizacion = Convert.ToString(parametros[5].Value);
            var outNumeroAutorizacion = Convert.ToString(parametros[4].Value);
            var outMensaje = Convert.ToString(parametros[8].Value);

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultado);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_VALIDA_PRECERTIFICACION(p_tipo_pss => {P_TIPO_PSS}, p_codigo_pss => {P_CODIGO_PSS}, p_compania => {P_COMPANIA}, p_num_precert => {P_NUM_PRECERT}, p_autoriza => {P_AUTORIZA}, p_origen => {P_ORIGEN}, p_outnum => {P_OUTNUM}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            tipoPss, codigoPss, compania, numeroPrecertificacion, outNumeroAutorizacion, outTipoAutorizacion, outCodigoValidacion, outResultado, outMensaje);

            return new ValidacionPrecertificacion
            {
                NumeroPrecertificacion = numeroPrecertificacion,
                TipoAutorizacion = outTipoAutorizacion,
                NumeroAutorizacion = outNumeroAutorizacion,
                CodigoValidacion = int.Parse(outCodigoValidacion)

            };
        }

        public async Task<CancelaPrecertificacion> CancelarPrecertificacion(string tipoPss, long? codigoPss, int? compania,
            long? numeroPrecertificacion)
        {
            var pResultado = new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output);
            var pMensaje = new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output);

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, tipoPss, ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_COMPANIA", OracleDbType.Int32, compania, ParameterDirection.Input),
                new OracleParameter("P_NUM_PRECERT", OracleDbType.Long, numeroPrecertificacion, ParameterDirection.InputOutput),
                pResultado,
                pMensaje
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_CANCELAR_PRECERTIFICACION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outResultado = int.Parse(pResultado.Value.ToString());
            var outMensaje = pMensaje.Value.ToString();

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultado);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_CANCELAR_PRECERTIFICACION(P_TIPO_PSS => {P_TIPO_PSS}, P_CODIGO_PSS => {P_CODIGO_PSS}, P_COMPANIA => {P_COMPANIA}, P_NUM_PRECERT => {P_NUM_PRECERT}, P_RESULTADO => {P_RESULTADO}, P_MENSAJE => {P_MENSAJE}); end;",
            tipoPss, codigoPss, compania, numeroPrecertificacion, outResultado, outMensaje);

            return new CancelaPrecertificacion
            {
                NumeroPrecertificacion = numeroPrecertificacion,
                CodigoValidacion = outResultado
            };
        }
    }
}