using GestionAutorizaciones.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Oracle.ManagedDataAccess.Client;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using GestionAutorizaciones.Infraestructure.Utils;
using static GestionAutorizaciones.Infraestructure.Utils.Constantes;
using System;
using GestionAutorizaciones.Application.Prestadores.Common;
using Microsoft.Extensions.Logging;

namespace GestionAutorizaciones.Infraestructure.Repositories
{
    public class PrestadorRepositorio : IPrestadorRepositorio
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger _logger;

        public PrestadorRepositorio(ApplicationDbContext context, ILogger<PrestadorRepositorio> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<Prestador> ObtenerInfoPss(string tipoPss, long codigoPss)
        {

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, tipoPss, ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_INFO_PSS", OracleDbType.RefCursor, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_INFO_PSS({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = (await _context.Set<Prestador>()
                .FromSqlRaw($"begin { procName }; end;", parametros)
                .ToListAsync())
                .FirstOrDefault();

            var outResultadoParam = int.Parse(parametros[3].Value.ToString());
            var outMensajeParam = parametros[4].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_OBTENER_INFO_PSS(p_tipo_pss => {P_TIPO_PSS}, p_codigo_pss => {P_CODIGO_PSS}, p_info_pss => {P_INFO_PSS}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            tipoPss, codigoPss, (result != null ? "(data)" : "(no data)"), outResultadoParam, outMensajeParam);

            return result;
        }

        public async Task<SalidaEstandar> ValidarPrestadorEsPaquete(long codigoPss, long pin)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_PIN", OracleDbType.Long, pin, ParameterDirection.Input),
                new OracleParameter("P_IND_APLICA", OracleDbType.Varchar2, 1 , null, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_ES_PSS_PAQUETE({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin { procName }; end;", parametros);

            var outEsPaquete = parametros[2].Value;
            var outResultadoParam = int.Parse(parametros[3].Value.ToString());
            var outMensajeParam = parametros[4].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_ES_PSS_PAQUETE(p_codigo_pss => {P_CODIGO_PSS}, p_pin => {P_PIN}, p_ind_aplica => {P_IND_APLICA}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            codigoPss, pin, outEsPaquete, outResultadoParam, outMensajeParam);

            return new SalidaEstandar
            {
                Aplica = Convert.ToString(outEsPaquete) == RespuestaProcedimiento.ResultadoPositivo,
                Resultado = Convert.ToString(outResultadoParam),
                Mensaje = Convert.ToString(outMensajeParam)
            };
        }

        public async Task<SalidaEstandar> ValidarPrestadorOfreceTipoCobertra(string tipoPss, long codigoPss, long tipoCobertura)
        {

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, tipoPss, ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_TIP_COB", OracleDbType.Long, tipoCobertura, ParameterDirection.Input),
                new OracleParameter("P_IND_APLICA", OracleDbType.Varchar2, 1 , null, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_PUEDE_PSS_OFRECER_TIP_COB({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin { procName }; end;", parametros);

            var outPuedeOfrecerCob = parametros[3].Value;
            var outResultadoParam = int.Parse(parametros[4].Value.ToString());
            var outMensajeParam = parametros[5].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_PUEDE_PSS_OFRECER_TIP_COB(p_tipo_pss => {P_TIPO_PSS}, p_codigo_pss => {P_CODIGO_PSS}, p_tip_cob => {P_TIP_COB}, p_ind_aplica => {P_IND_APLICA}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            tipoPss, codigoPss, tipoCobertura, outPuedeOfrecerCob, outResultadoParam, outMensajeParam);

            return new SalidaEstandar
            {
                Aplica = Convert.ToString(outPuedeOfrecerCob) == RespuestaProcedimiento.ResultadoPositivo,
                Resultado = Convert.ToString(outResultadoParam),
                Mensaje = Convert.ToString(outMensajeParam),
            };
        }

        public async Task<SalidaEstandar> ValidarPrestadorOfreceServicio(string tipoPss, long codigoPss, long mumeroAsegurado, int secuenciaDependiente)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, tipoPss, ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_ASEGURADO", OracleDbType.Long, mumeroAsegurado, ParameterDirection.Input),
                new OracleParameter("P_DEPENDIENTE", OracleDbType.Int16, secuenciaDependiente, ParameterDirection.Input),
                new OracleParameter("P_IND_APLICA", OracleDbType.Varchar2, 1 , null, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_PUEDE_PSS_DAR_SERVICIO({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin { procName }; end;", parametros);

            var outPuedeDarServicio = parametros[4].Value;
            var outResultadoParam = int.Parse(parametros[5].Value.ToString());
            var outMensajeParam = parametros[6].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_PUEDE_PSS_DAR_SERVICIO(p_tipo_pss => {P_TIPO_PSS}, p_codigo_pss => {P_CODIGO_PSS}, p_asegurado => {P_ASEGURADO}, p_dependiente => {P_DEPENDIENTE}, p_ind_aplica => {P_IND_APLICA}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            tipoPss, codigoPss, mumeroAsegurado, secuenciaDependiente, outPuedeDarServicio, outResultadoParam, outMensajeParam);

            return new SalidaEstandar
            {
                Aplica = Convert.ToString(outPuedeDarServicio) == RespuestaProcedimiento.ResultadoPositivo,
                Resultado = Convert.ToString(outResultadoParam),
                Mensaje = Convert.ToString(outMensajeParam)
            };
        }

        public async Task<IEnumerable<ReclamacionPss>> ObtenerReclamacionesPss(string tipoPss, long codigoPss, DateTime fechaInicio,
            DateTime fechaFin, int? ramo, long? secuencial, string usuarioIngreso, long? numeroPlastico, int? compania)
        {

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, tipoPss, ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_FECHA_INICIO", OracleDbType.Date, fechaInicio, direction: ParameterDirection.Input),
                new OracleParameter("P_FECHA_FIN", OracleDbType.Date, fechaFin, direction: ParameterDirection.Input),
                new OracleParameter("P_RAMO", OracleDbType.Int32, ramo, ParameterDirection.Input),
                new OracleParameter("P_SECUENCIAL", OracleDbType.Long, secuencial, ParameterDirection.Input),
                new OracleParameter("P_USU_ING", OracleDbType.Varchar2, usuarioIngreso, ParameterDirection.Input),
                new OracleParameter("P_NUM_PLASTICO", OracleDbType.Long, numeroPlastico, ParameterDirection.Input),
                new OracleParameter("P_COMPANIA", OracleDbType.Int32, compania, ParameterDirection.Input),
                new OracleParameter("P_RECLAMACIONES", OracleDbType.RefCursor, direction: ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_RECLAMACIONES_PSS({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = (await _context.Set<ReclamacionPss>()
                .FromSqlRaw($"begin { procName }; end;", parametros)
                .ToListAsync());

            int.TryParse(parametros[9].Value.ToString(), out int outResultado);
            var outMensaje = parametros[10].Value.ToString();

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultado);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_OBTENER_RECLAMACIONES_PSS(p_tipo_pss => {P_TIPO_PSS}, p_codigo_pss => {P_CODIGO_PSS}, p_fecha_inicio => {P_FECHA_INICIO}, , p_fecha_fin => {P_FECHA_FIN}, p_ramo => {P_RAMO}, p_secuencial => {P_SECUENCIAL}, p_usu_ing => {P_USU_ING}, p_num_plastico => {P_NUM_PLASTICO}, p_compania => {P_COMPANIA}, p_reclamaciones => {P_RECLAMACIONES}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            tipoPss, codigoPss, fechaInicio, fechaFin, ramo, secuencial, usuarioIngreso, numeroPlastico, compania, (result != null ? "(data)" : "(no data)"), outResultado, outMensaje);
            
            return result;
        }

        public async Task<TipoPrestador> ObtenerTipoPrestador(long codigoPss, long pin)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, ParameterDirection.Input),
                new OracleParameter("P_PIN", OracleDbType.Long, pin, ParameterDirection.Input),
                new OracleParameter("P_TIPO_PSS", OracleDbType.Varchar2, 10 , null, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_TIPO_PSS({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin { procName }; end;", parametros);

            var outTipoPss = parametros[2].Value.ToString();
            var outResultadoParam = parametros[3].Value.ToString();
            var outMensajeParam = parametros[4].Value.ToString();

            var logLevel = LoggerUtils.LogLevelResultadoParam(int.Parse(outResultadoParam));
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_OBTENER_TIPO_PSS(p_codigo_pss => {P_CODIGO_PSS}, p_pin => {P_PIN}, p_tipo_pss => {P_TIPO_PSS}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            codigoPss, pin, outTipoPss, outResultadoParam, outMensajeParam);

            return new TipoPrestador
            {
                Descripcion = outTipoPss,
                Resultado = outResultadoParam,
                Mensaje = outMensajeParam
            };
        }

        public async Task<SalidaEstandar> ConfirmarReclamacion(int ano, int compania, int ramo, long secuencial, long codigoPss)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_ANO", OracleDbType.Int32, ano, direction: ParameterDirection.Input),
                new OracleParameter("P_COMPANIA", OracleDbType.Int32, compania, direction: ParameterDirection.Input),
                new OracleParameter("P_RAMO", OracleDbType.Int32, ramo, direction: ParameterDirection.Input),
                new OracleParameter("P_SECUENCIAL", OracleDbType.Long, secuencial, direction: ParameterDirection.Input),
                new OracleParameter("P_CODIGO_PSS", OracleDbType.Long, codigoPss, direction: ParameterDirection.Input),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_CONFIRMAR_RECLAMACION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin { procName }; end;", parametros);

            var outResultadoParam = parametros[4].Value.ToString();
            var outMensajeParam = parametros[5].Value.ToString();

            var logLevel = LoggerUtils.LogLevelResultadoParam(int.Parse(outResultadoParam));
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_CONFIRMAR_RECLAMACION(p_ano => {P_ANO}, p_compania => {P_COMPANIA}, p_ramo => {P_RAMO}, p_secuencial => {P_SECUENCIAL}, p_codigo_pss => {P_CODIGO_PSS}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            ano, compania, ramo, secuencial, codigoPss, outResultadoParam, outMensajeParam);

            return new SalidaEstandar
            {
                Resultado = outResultadoParam,
                Mensaje = outMensajeParam
            };
        }
    }
}