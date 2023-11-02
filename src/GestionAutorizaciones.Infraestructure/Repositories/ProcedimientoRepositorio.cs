using GestionAutorizaciones.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Oracle.ManagedDataAccess.Client;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using GestionAutorizaciones.Infraestructure.Utils;
using static GestionAutorizaciones.Infraestructure.Utils.Constantes;
using System;
using GestionAutorizaciones.Application.Procedimientos.Common;
using Microsoft.Extensions.Logging;

namespace GestionAutorizaciones.Infraestructure.Repositories
{
    public class ProcedimientoRepositorio : IProcedimientoRepositorio
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger _logger;
        public ProcedimientoRepositorio(ApplicationDbContext context, ILogger<ProcedimientoRepositorio> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<SalidaEstandar> ValidarPasaReglasCobertura(long numeroSesion, long tipoServicio, long cobertura)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_NUMSESSION", OracleDbType.Long, numeroSesion, ParameterDirection.Input),
                new OracleParameter("P_SERVICIO", OracleDbType.Long, tipoServicio, ParameterDirection.Input),
                new OracleParameter("P_COBERTURA", OracleDbType.Long, cobertura, ParameterDirection.Input),
                new OracleParameter("P_IND_APLICA", OracleDbType.Varchar2, 1 , null, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };


            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_VALIDA_REGLAS_COBERTURA({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin { procName }; end;", parametros);

            var outPasaReglas = parametros[3].Value;
            var outResultadoParam = parametros[4].Value;
            var outMensajeParam = parametros[5].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(int.Parse(outResultadoParam.ToString()));
            _logger.Log(logLevel, 
            "begin AUTORIZACIONES.P_VALIDA_REGLAS_COBERTURA(p_numsession => {P_NUMSESSION}, p_servicio => {P_SERVICIO}, p_cobertura => {P_COBERTURA}, p_ind_aplica => {P_IND_APLICA}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            numeroSesion, tipoServicio, cobertura, outPasaReglas, outResultadoParam, outMensajeParam);

            return new SalidaEstandar
            {
                Aplica = Convert.ToString(outPasaReglas) == RespuestaProcedimiento.ResultadoPositivo,
                Resultado = Convert.ToString(outResultadoParam),
                Mensaje = Convert.ToString(outMensajeParam)
            };


        }

        public async Task<SalidaEstandar> ValidarCoberturaLaboratorio(long cobertura)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_COBERTURA", OracleDbType.Long, cobertura, ParameterDirection.Input),
                new OracleParameter("P_IND_APLICA", OracleDbType.Varchar2, 1 , null, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };


            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_ES_COBERTURA_LABORATORIO({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin { procName }; end;", parametros);

            var outEsLaboratorio = parametros[1].Value;
            var outResultadoParam = parametros[2].Value;
            var outMensajeParam = parametros[3].Value;


            var logLevel = LoggerUtils.LogLevelResultadoParam(int.Parse(outResultadoParam.ToString()));
            _logger.Log(logLevel, 
            "begin AUTORIZACIONES.P_ES_COBERTURA_LABORATORIO(p_cobertura => {P_COBERTURA}, p_ind_aplica => {P_IND_APLICA}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            cobertura, outEsLaboratorio, outResultadoParam, outMensajeParam);

            return new SalidaEstandar
            {
                Aplica = Convert.ToString(outEsLaboratorio) == RespuestaProcedimiento.ResultadoPositivo,
                Resultado = Convert.ToString(outResultadoParam),
                Mensaje = Convert.ToString(outMensajeParam)
            };


        }

        public async Task<SalidaEstandar> ValidarCoberturaConsulta(long cobertura)
        {

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_COBERTURA", OracleDbType.Long, cobertura, ParameterDirection.Input),
                new OracleParameter("P_IND_APLICA", OracleDbType.Varchar2, 1 , null, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };


            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_ES_COBERTURA_CONSULTA({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin { procName }; end;", parametros);

            var outEsConsulta = parametros[1].Value;
            var outResultadoParam = parametros[2].Value;
            var outMensajeParam = parametros[3].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(int.Parse(outResultadoParam.ToString()));
            _logger.Log(logLevel, 
            "begin AUTORIZACIONES.P_ES_COBERTURA_CONSULTA(p_cobertura => {P_COBERTURA}, p_ind_aplica => {P_IND_APLICA}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            cobertura, outEsConsulta, outResultadoParam, outMensajeParam);

            return new SalidaEstandar
            {
                Aplica = Convert.ToString(outEsConsulta) == RespuestaProcedimiento.ResultadoPositivo,
                Resultado = Convert.ToString(outResultadoParam),
                Mensaje = Convert.ToString(outMensajeParam)
            };

        }


        public async Task<IEnumerable<Procedimiento>> ObtenerProcedimientos(string tipoPss, long codigoPss, long? servicio)
        {

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, tipoPss, ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_SERVICIO", OracleDbType.Long, servicio, ParameterDirection.Input),
                new OracleParameter("P_PROCEDIMIENTOS", OracleDbType.RefCursor, direction: ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output),
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_PROCEDIMIENTOS_PSS({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = (await _context.Set<Procedimiento>()
                .FromSqlRaw($"begin { procName }; end;", parametros)
                .ToListAsync());

            var outResultadoParam = int.Parse(parametros[4].Value.ToString());
            var outMensajeParam = parametros[5].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_OBTENER_PROCEDIMIENTOS_PSS(p_tipo_pss => {P_TIPO_PSS}, p_codigo_pss => {P_CODIGO_PSS}, p_servicio => {P_SERVICIO}, p_procedimientos => {P_PROCEDIMIENTOS}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            tipoPss, codigoPss, servicio, (result != null ? "(data)" : "(no data)"), outResultadoParam, outMensajeParam);

            return result;
        }

        public async Task<SalidaEstandar> ValidarEstudioEspecial(long servicio, long cobertura, string tipoCanal)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("PSERVICIO", OracleDbType.Long, servicio, direction: ParameterDirection.Input),
                new OracleParameter("PCOBERTURA", OracleDbType.Long, cobertura, direction: ParameterDirection.Input),
                new OracleParameter("PTIPO_CANAL", OracleDbType.Varchar2, tipoCanal, direction: ParameterDirection.Input),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, direction: ParameterDirection.ReturnValue),
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.VALIDA_ESTUDIOS_ESPECIALES({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin { procName }; end;", parametros);

            var outResultadoParam = parametros[3].Value;

            return new SalidaEstandar
            {
                Aplica = Convert.ToInt32(outResultadoParam) == 1,
            };
        }

        public async Task<IEnumerable<ProcedimientoNoServicio>> ObtenerProcedimientosNoServicio(string tipoPss, long codigoPss, long? servicio)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, tipoPss, ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_SERVICIO", OracleDbType.Long, servicio, ParameterDirection.Input),
                new OracleParameter("P_PROCEDIMIENTOS", OracleDbType.RefCursor, direction: ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output),
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_PROCEDIMIENTOS_PSSV2({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = (await _context.Set<ProcedimientoNoServicio>()
                .FromSqlRaw($"begin {procName}; end;", parametros)
                .ToListAsync());

            var outResultadoParam = int.Parse(parametros[4].Value.ToString());
            var outMensajeParam = parametros[5].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_OBTENER_PROCEDIMIENTOS_PSSV2(p_tipo_pss => {P_TIPO_PSS}, p_codigo_pss => {P_CODIGO_PSS}, p_servicio => {P_SERVICIO}, p_procedimientos => {P_PROCEDIMIENTOS}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            tipoPss, codigoPss, servicio, (result != null ? "(data)" : "(no data)"), outResultadoParam, outMensajeParam);

            return result;
        }
    }
}
