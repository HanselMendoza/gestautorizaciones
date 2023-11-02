using System;
using System.Data;
using System.Threading.Tasks;
using System.Collections.Generic;
using GestionAutorizaciones.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Oracle.ManagedDataAccess.Client;
using System.Linq;
using GestionAutorizaciones.Infraestructure.Utils;
using GestionAutorizaciones.Application.Asegurado.Common;
using Microsoft.Extensions.Logging;

namespace GestionAutorizaciones.Infraestructure.Repositories
{
    public class AseguradoRepositorio : IAseguradoRepositorio
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger _logger;

        public AseguradoRepositorio(ApplicationDbContext context, ILogger<AseguradoRepositorio> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<SalidaEstandar> ValidarAfiliadoAplicaPBS(long numeroPlastico, DateTime fecha)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_NUM_PLASTICO", OracleDbType.Long, numeroPlastico, direction: ParameterDirection.Input),
                new OracleParameter("P_FEC_SER", OracleDbType.Date, fecha, direction: ParameterDirection.Input),
                new OracleParameter("P_IND_APLICA", OracleDbType.Varchar2, 1, null, direction: ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, direction: ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, direction: ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_ASEGURADO_TIENE_SOLO_PBS({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var outAplicaParam = parametros[2].Value;
            var outResultadoParam = int.Parse(parametros[3].Value.ToString());
            var outMensajeParam = parametros[4].Value;

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultadoParam);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_ASEGURADO_TIENE_SOLO_PBS(p_num_plastico => {P_NUM_PLASTICO}, p_fec_ser => {P_FEC_SER}, p_ind_aplica => {P_IND_APLICA}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            numeroPlastico, fecha, outAplicaParam, outResultadoParam, outMensajeParam);

            return new SalidaEstandar
            {
                Aplica = Convert.ToBoolean(outAplicaParam),
                Resultado = Convert.ToString(outResultadoParam),
                Mensaje = Convert.ToString(outMensajeParam),
            };
        }

        public async Task<Telefono> ObtenerTelefono(long numeroPlastico)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_NUM_PLASTICO", OracleDbType.Long, numeroPlastico, ParameterDirection.Input),
                new OracleParameter("P_TELEFONO", OracleDbType.Varchar2, 15, null, direction:  ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int32, direction: ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, direction: ParameterDirection.Output),
            };


            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_TELEFONO_PLASTICO({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outTelefono = parametros[1].Value?.ToString();
            var outResultado = parametros[2].Value?.ToString();
            var outMensaje = parametros[3].Value?.ToString();

            var logLevel = LoggerUtils.LogLevelResultadoParam(int.Parse(outResultado));
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_OBTENER_TELEFONO_PLASTICO(p_num_plastico => {P_NUM_PLASTICO}, p_telefono => {P_TELEFONO}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            numeroPlastico, outTelefono, outResultado, outMensaje);

            return new Telefono
            {
                NumeroTelefono = outTelefono,
                Resultado = outResultado,
                Mensaje = outMensaje
            };
        }

        public async Task<OrigenPlastico> ObtenerOrigenPlastico(long numeroPlastico)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_NUM_PLA", OracleDbType.Long, numeroPlastico, ParameterDirection.Input),
                new OracleParameter("P_CODIGO", OracleDbType.Varchar2, 10, null, direction: ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int32, direction: ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, direction: ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_DETERMINA_ORIGEN_POR_NUM_PLA({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outCodigo = parametros[1].Value?.ToString();
            var outResultado = parametros[2].Value?.ToString();
            var outMensaje = parametros[3].Value?.ToString();

            var logLevel = LoggerUtils.LogLevelResultadoParam(int.Parse(outResultado));
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_DETERMINA_ORIGEN_POR_NUM_PLA(p_num_plastico => {P_NUM_PLASTICO}, p_codigo => {P_CODIGO}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            numeroPlastico, outCodigo, outResultado, outMensaje);

            return new OrigenPlastico
            {
                Codigo = outCodigo,
                Resultado = outResultado,
                Mensaje = outMensaje
            };
        }

        public async Task<IEnumerable<Nucleo>> ObtenerNucleos(long numeroPlastico)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_NUM_PLASTICO", OracleDbType.Int32, numeroPlastico, ParameterDirection.Input),
                new OracleParameter("P_NUCLEO", OracleDbType.RefCursor, direction: ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int32, direction: ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, direction: ParameterDirection.Output)
            };


            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_OBTENER_NUCLEO_POR_NUM_PLA({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = await _context.Set<Nucleo>()
                .FromSqlRaw($"begin {procName}; end;", parametros)
                .ToListAsync();

            var outResultado = int.Parse(parametros[2].Value?.ToString());
            var outMensaje = parametros[3].Value?.ToString();

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultado);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_OBTENER_NUCLEO_POR_NUM_PLA(p_num_plastico => {P_NUM_PLASTICO}, p_nucleo => {P_NUCLEO}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            numeroPlastico, (result != null ? "(data)" : "(no data)"), outResultado, outMensaje);

            return result;
        }

        public async Task<Afiliado> ObtenerAfiliado(string tipoId, string identificacion, int compania)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_TIPO_ID", OracleDbType.Varchar2, tipoId, ParameterDirection.Input),
                new OracleParameter("P_IDENTIFICACION", OracleDbType.Varchar2, identificacion, ParameterDirection.Input),
                new OracleParameter("P_COMPANIA", OracleDbType.Int32, compania, ParameterDirection.Input),
                new OracleParameter("P_AFILIADO", OracleDbType.RefCursor, ParameterDirection.Output),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, ParameterDirection.Output),
                new OracleParameter("P_MENSAJE", OracleDbType.Varchar2, 1000, null, ParameterDirection.Output)
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.P_BUSCA_AFILIADO({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            var result = (await _context.Set<Afiliado>()
                .FromSqlRaw($"begin {procName}; end;", parametros)
                .ToListAsync())
                .FirstOrDefault();

            var outResultado = int.Parse(parametros[4].Value?.ToString());
            var outMensaje = parametros[5].Value?.ToString();

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultado);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.P_BUSCA_AFILIADO(p_tipo_id => {P_TIPO_ID}, p_identificacion => {P_IDENTIFICACION}, p_compania => {P_COMPANIA}, p_afiliado => {P_AFILIADO}, p_resultado => {P_RESULTADO}, p_mensaje => {P_MENSAJE}); end;",
            tipoId, identificacion, compania, (result != null ? "(data)" : "(no data)"), outResultado, outMensaje);

            return result;
        }

        public async Task<SalidaEstandar> ValidarAfiliadoAgotoConsultasAmbulatorias(long numeroPlastico, string tipoCanal, DateTime fechaServicio)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("PNUM_PLA", OracleDbType.Long, numeroPlastico, direction: ParameterDirection.Input),
                new OracleParameter("PTIPO_CANAL", OracleDbType.Varchar2, tipoCanal, direction: ParameterDirection.Input),
                new OracleParameter("PFECHA_SER", OracleDbType.Date, fechaServicio, direction: ParameterDirection.Input),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, direction: ParameterDirection.ReturnValue),
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.LIMITE_CONSULTA_MEDICA({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outResultado = int.Parse(parametros[parametros.Length - 1]?.Value.ToString());

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultado);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.LIMITE_CONSULTA_MEDICA(pnum_pla => {PNUM_PLA}, ptipo_canal => {PTIPO_CANAL}, pfecha_ser => {PFECHA_SER}, p_resultado => {P_RESULTADO}); end;",
            numeroPlastico, tipoCanal, fechaServicio, outResultado);

            return new SalidaEstandar
            {
                Aplica = outResultado == 0,
            };
        }

        public async Task<SalidaEstandar> ValidarAfiliadoTieneConsultasPrevias(long numeroPlastico, string tipoCanal, DateTime fechaServicio, long centro, string tipoReclamante)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("PNUM_PLA", OracleDbType.Long, numeroPlastico, direction: ParameterDirection.Input),
                new OracleParameter("PTIPO_CANAL", OracleDbType.Varchar2, tipoCanal, direction: ParameterDirection.Input),
                new OracleParameter("PFECHA_SER", OracleDbType.Date, fechaServicio, direction: ParameterDirection.Input),
                new OracleParameter("P_CENTRO", OracleDbType.Long, centro, direction: ParameterDirection.Input),
                new OracleParameter("P_TIP_REC", OracleDbType.Varchar2, tipoReclamante, direction: ParameterDirection.Input),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, direction: ParameterDirection.ReturnValue),
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.VALIDA_CONSULTA_MEDICA({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outResultado = int.Parse(parametros[parametros.Length - 1]?.Value.ToString());

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultado);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.VALIDA_CONSULTA_MEDICA(pnum_pla => {PNUM_PLA}, ptipo_canal => {PTIPO_CANAL}, pfecha_ser => {PFECHA_SER}, p_centro => {P_CENTRO}, p_tip_rec => {P_TIP_REC}, p_resultado => {P_RESULTADO}); end;",
            numeroPlastico, tipoCanal, fechaServicio, centro, tipoReclamante, outResultado);

            return new SalidaEstandar
            {
                Aplica = outResultado == 1,
            };
        }

        public async Task<SalidaEstandar> ValidarAfiliadoSoloTieneEmergencia(long numeroPlastico)
        {
            var parametros = new OracleParameter[]
            {
                new OracleParameter("P_NUM_PLA", OracleDbType.Long, numeroPlastico, direction: ParameterDirection.Input),
                new OracleParameter("P_RESULTADO", OracleDbType.Int16, direction: ParameterDirection.ReturnValue),
            };

            var paramNames = DbUtils.ParametersToString(parametros);
            var procName = $"AUTORIZACIONES.VALIDA_SERVICIO_EMERGENCIA({paramNames})";
            _logger.LogInformation($"Starting {procName}");

            await _context.Database.ExecuteSqlRawAsync($"begin {procName}; end;", parametros);

            var outResultado = int.Parse(parametros[parametros.Length - 1]?.Value.ToString());

            var logLevel = LoggerUtils.LogLevelResultadoParam(outResultado);
            _logger.Log(logLevel,
            "begin AUTORIZACIONES.VALIDA_SERVICIO_EMERGENCIA(p_num_pla => {P_NUM_PLA}, p_resultado => {P_RESULTADO}); end;",
            numeroPlastico, outResultado);

            return new SalidaEstandar
            {
                Aplica = outResultado == 1,
            };
        }
    }
}
