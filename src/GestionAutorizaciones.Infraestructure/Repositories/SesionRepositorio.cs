using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Domain.Entities;
using GestionAutorizaciones.Infraestructure.Utils;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Oracle.ManagedDataAccess.Client;

namespace GestionAutorizaciones.Infraestructure.Repositories
{
    public class SesionRepositorio : ISesionRepositorio
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger _logger;

        public SesionRepositorio(ApplicationDbContext context, ILogger<SesionRepositorio> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<RespuestaInfoxProc> Infoxproc(string nombreFuncion, long numeroSesion, string instruccion1, string instruccion2, int? innum1, int? innum2, string usuarioRegistra = null)
        {
            var accionParametro = new OracleParameter("p_name", OracleDbType.Varchar2, nombreFuncion, direction: ParameterDirection.Input);
            var numeroSesionParametro = new OracleParameter("p_numsession", OracleDbType.Int32, numeroSesion, direction: ParameterDirection.Input);
            var instruccion1Parametro = new OracleParameter("p_instr1", OracleDbType.Varchar2, instruccion1, direction: ParameterDirection.Input);
            var instrucción2Parametro = new OracleParameter("p_instr2", OracleDbType.Varchar2, instruccion2, direction: ParameterDirection.Input);
            var innum1Parametro = new OracleParameter("p_innum1", OracleDbType.Int32, innum1, direction: ParameterDirection.Input);
            var innum2Parametro = new OracleParameter("p_innum2", OracleDbType.Int32, innum2, direction: ParameterDirection.Input);
            var userRegisterParametro = new OracleParameter("p_user_register", OracleDbType.Varchar2, usuarioRegistra, direction: ParameterDirection.Input);
            var outstr1Parametro = new OracleParameter("p_outstr1", OracleDbType.Varchar2, 1000, null, direction: ParameterDirection.Output);
            var outstr2Parametro = new OracleParameter("p_outstr2", OracleDbType.Varchar2, 1000, null, direction: ParameterDirection.Output);
            var outnum1Parametro = new OracleParameter("p_outnum1", OracleDbType.Int32, direction: ParameterDirection.Output);
            var outnum2Parametro = new OracleParameter("p_outnum2", OracleDbType.Int32, direction: ParameterDirection.Output);

            _logger.LogInformation("Starting AUTORIZACIONES.infoxproc");
            await _context.Database.ExecuteSqlRawAsync
                        ("BEGIN AUTORIZACIONES.infoxproc(:p_name, :p_numsession, :p_instr1, :p_instr2, :p_innum1, :p_innum2, :p_user_register, :p_outstr1, :p_outstr2, :p_outnum1, :p_outnum2); END;",
                            accionParametro, numeroSesionParametro, instruccion1Parametro, instrucción2Parametro, innum1Parametro,
                            innum2Parametro, userRegisterParametro, outstr1Parametro, outstr2Parametro, outnum1Parametro, outnum2Parametro);

            _logger.LogInformation(
                "BEGIN AUTORIZACIONES.infoxproc(p_name => {p_name}, p_numsession => {p_numsession}, p_instr1 => {p_instr1}, p_instr2 => {p_instr2}, p_innum1 => {p_innum1}, p_innum2 => {p_innum2}, p_user_register => {p_user_register}, p_outstr1 => {p_outstr1}, p_outstr2 => {p_outstr2}, p_outnum1 => {p_outnum1}, p_outnum2 => {p_outnum2}); END;",
                nombreFuncion, numeroSesion, instruccion1, instruccion2, innum1, innum2, usuarioRegistra, outstr1Parametro.Value, outstr2Parametro.Value, outnum1Parametro.Value, outnum2Parametro.Value);

            var resultOutstr1Parametro = outstr1Parametro.Value;
            var resultOutstr2Parametro = outstr2Parametro.Value;
            var resultOutnum1Parametro = outnum1Parametro.Value.ToString();
            var resultOutnum2Parametro = outnum2Parametro.Value.ToString();

            var respuestaInfoxProc = new RespuestaInfoxProc
            {
                Outstr1 = resultOutstr1Parametro.ToString(),
                Outstr2 = resultOutstr2Parametro.ToString(),
                Outnum1 = resultOutnum1Parametro,
                Outnum2 = resultOutnum2Parametro
            };

            return respuestaInfoxProc;
        }

        public async Task<InfoSesion> ObtenerInfoSesion(long numeroSesion)
        {

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_NUMSESSION", OracleDbType.Long, numeroSesion, ParameterDirection.Input),
                new OracleParameter("P_INFOX_SESSION", OracleDbType.RefCursor, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_INFOX_SESSION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = (await _context.Set<InfoSesion>()
                .FromSqlRaw($"begin {procName}; end;", parametros)
                .ToListAsync())
                .FirstOrDefault();

            var outResultadoParam = int.Parse(parametros[2].Value.ToString());
            var outMensajeParam = parametros[3].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
                "begin AUTORIZACIONES.P_OBTENER_INFOX_SESSION(p_numsession => {P_NUMSESSION}, p_infox_session => {P_INFOX_SESSION}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
                numeroSesion, (result != null ? "(data)" : "(no data)"), outResultadoParam, outMensajeParam);

            return result;

        }

        public async Task<SalidaEstandar> ActualizarInfoSession(long numeroSesion, InfoSesion datosSession)
        {
            char? esSoloPbs = datosSession.EsSoloPbs is null ? null : (char?)Convert.ToChar(datosSession.EsSoloPbs);
            char? esPssPaquete = datosSession.EsPssPaquete is null ? null : (char?)Convert.ToChar(datosSession.EsPssPaquete);
            char? tieneExcesoPorGrupo = datosSession.TieneExcesoPorGrupo is null ? null : (char?)Convert.ToChar(datosSession.TieneExcesoPorGrupo);

            var parametros = new OracleParameter[]
            {

                new OracleParameter("P_NUMSESSION", OracleDbType.Long, numeroSesion, ParameterDirection.Input),
                new OracleParameter("P_ESTATUS", OracleDbType.Int32, datosSession.Estatus, ParameterDirection.Input),
                new OracleParameter("P_ES_SOLO_PBS", OracleDbType.Char, esSoloPbs, ParameterDirection.Input),
                new OracleParameter("P_ES_PSS_PAQUETE", OracleDbType.Char,esPssPaquete, ParameterDirection.Input),
                new OracleParameter("P_TIENE_EXCESOPORGRUPO", OracleDbType.Char, tieneExcesoPorGrupo, ParameterDirection.Input),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_ACTUALIZA_INFOX_SESSION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outResultadoParam = int.Parse(parametros[5].Value.ToString());
            var outMensajeParam = parametros[6].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_ACTUALIZA_INFOX_SESSION(p_numsession => {P_NUMSESSION}, p_estatus => {P_ESTATUS}, p_es_solo_pbs => {P_ES_SOLO_PBS}, p_es_pss_paquete => {P_ES_PSS_PAQUETE}, p_tiene_excesoporgrupo => {P_TIENE_EXCESOPORGRUPO}, p_resultado => {P_RESULTADO}, p_mensaje {P_MENSAJE}); end;",
            numeroSesion, datosSession.Estatus, esSoloPbs, esPssPaquete, tieneExcesoPorGrupo, outResultadoParam, outMensajeParam);

            return new SalidaEstandar
            {
                Aplica = Convert.ToString(outResultadoParam) == "0",
                Resultado = Convert.ToString(outResultadoParam),
                Mensaje = Convert.ToString(outMensajeParam),
            };

        }

        public async Task<List<DetalleReclamacion>> ObtenerDetalleReclamacion(long numeroSesion)
        {

            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_NUMSESSION", OracleDbType.Long, numeroSesion, ParameterDirection.Input),
                new OracleParameter("P_DET_RECLAMACION", OracleDbType.RefCursor, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_DET_RECLAMACION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = (await _context.Set<DetalleReclamacion>()
                .FromSqlRaw($"begin {procName}; end;", parametros)
                .ToListAsync());

            var outResultadoParam = int.Parse(parametros[2].Value.ToString());
            var outMensajeParam = parametros[3].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_OBTENER_DET_RECLAMACION(p_numsession => {P_NUMSESSION}, p_det_reclamacion => {P_DET_RECLAMACION}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            numeroSesion, (result != null ? "(data)" : "(no data)"), outResultadoParam, outMensajeParam);

            return result;

        }

        public async Task<SolicitudArl> MarcarComoArl(long numeroSesion)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_NUMSESSION", OracleDbType.Long, numeroSesion, direction: ParameterDirection.Input),
                new OracleParameter("P_ID_SOLICITUD", OracleDbType.Long, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_MARCAR_COMO_ARL({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outNumeroSolicitud = parametros[1].Value;
            var outResultadoParam = int.Parse(parametros[2].Value.ToString());
            var outMensajeParam = parametros[3].Value;

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_MARCAR_COMO_ARL(p_numsession => {P_NUMSESSION}, p_id_soliciutd => {P_ID_SOLICITUD}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            numeroSesion, outNumeroSolicitud, outResultadoParam, outMensajeParam);

            return new SolicitudArl
            {
                NumeroSolicitud = Convert.ToUInt16(outNumeroSolicitud),
                Resultado = Convert.ToString(outResultadoParam),
                Mensaje = Convert.ToString(outMensajeParam),
            };
        }

        public async Task<Sesion> ReactivarSesion(int? ano, int? compania, int? ramo, long? secuencial)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_ANO", OracleDbType.Int64, ano, direction: ParameterDirection.Input),
                new OracleParameter("P_COMPANIA", OracleDbType.Int64, compania, direction: ParameterDirection.Input),
                new OracleParameter("P_RAMO", OracleDbType.Int64, ramo, direction: ParameterDirection.Input),
                new OracleParameter("P_RECLAMACION", OracleDbType.Long, secuencial, direction: ParameterDirection.Input),
                new OracleParameter("P_NUMSESSION", OracleDbType.Long,1000, null, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_REACTIVAR_SESSION({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outNumeroSesion = Convert.ToString(parametros[4].Value);
            var outResultado = Convert.ToString(parametros[5].Value);
            var outMensaje = Convert.ToString(parametros[6].Value);

            var logLevel = LoggerUtils.LogLevelResultadoParam(int.Parse(outResultado));
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_REACTIVAR_SESSION(p_ano => {P_ANO}, p_compania => {P_COMPANIA}, p_ramo => {P_RAMO}, p_reclamacion => {P_RECLAMACION}, p_numsession => {P_NUMSESSION}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            ano, compania, ramo, secuencial, outNumeroSesion, outResultado, outMensaje);

            return new Sesion
            {
                NumeroSesion = long.TryParse(outNumeroSesion, out _) ? long.Parse(outNumeroSesion) : 0,
                Resultado = outResultado,
                Mensaje = outMensaje
            };
        }

    }
}

