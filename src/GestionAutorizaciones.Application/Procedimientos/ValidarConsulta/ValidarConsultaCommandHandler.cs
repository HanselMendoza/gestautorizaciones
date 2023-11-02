using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;
using Microsoft.AspNetCore.Http;
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using GestionAutorizaciones.Application.Common.Handlers;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using GestionAutorizaciones.Application.Procedimientos.Common;
using GestionAutorizaciones.Application.Sesion.Common;
using Microsoft.Extensions.Options;
using GestionAutorizaciones.Application.Common.Options;

namespace GestionAutorizaciones.Application.Procedimientos.ValidarConsulta

{
    public class ValidarConsultaCommandHandler : BaseHandler<ValidarConsultaCommand, ValidarConsultaResponseDto>
    {
        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IProcedimientoRepositorio _procedimientoRepositorio;
        private readonly ParametrosConfig _parametrosConfig;
        private static readonly IDictionary<string, string> _errorCodes = new Dictionary<string, string>{
            {
                RespuestaInfoxprocValidaCobertura.CoberturaNoDisponibleParaAsegurado,
                MensajeInfoxproc.CoberturaNoDisponibleParaAsegurado
            },
            {
                RespuestaInfoxprocValidaCobertura.PrestadorNoOfreceCobertura,
                MensajeInfoxproc.PrestadorNoOfreceCobertura
            }

        };


        public ValidarConsultaCommandHandler(ISesionRepositorio sesionRepositorio,
            IProcedimientoRepositorio procedimientoRepositorio,
            IOptions<ParametrosConfig> parametrosConfig)
        {
            _sesionRepositorio = sesionRepositorio;
            _procedimientoRepositorio = procedimientoRepositorio;
            _parametrosConfig = parametrosConfig.Value;
        }

        public async override Task<ResponseDto<ValidarConsultaResponseDto>> Handle(ValidarConsultaCommand request, CancellationToken cancellationToken)
        {
            var servicio = _parametrosConfig.ServicioConsulta.Servicio;
            var codCobertura = _parametrosConfig.ServicioConsulta.Cobertura.Value;

            var resultValidarReglas = await _procedimientoRepositorio.ValidarPasaReglasCobertura(
                request.NumeroSesion, servicio, codCobertura);

            var aplicaValidacion = EsValida(resultValidarReglas.Resultado) &&
                    resultValidarReglas.Aplica.Value;
            if (!aplicaValidacion)
            {
                return Error(StatusCodes.Status400BadRequest, MensajeInfoxproc.CoberturaNoAplicaTipoServicio);
            }

            var cobertura = _parametrosConfig.ServicioConsulta.ToString();
            string monto = null;
            int frecuencia = 1;

            var resultValidarProcedimiento = await _sesionRepositorio.Infoxproc(NombreOperacion.ValidarCobertura, request.NumeroSesion,
                cobertura, monto, frecuencia, null, request.UsuarioRegistra);


            if (resultValidarProcedimiento.Outnum1 == RespuestaInfoxprocValidaCobertura.CoberturaValida)
            {
                var montoCubierto = decimal.Parse(resultValidarProcedimiento.Outstr1);
                var montoAfiliado = string.IsNullOrWhiteSpace(resultValidarProcedimiento.Outstr2) || resultValidarProcedimiento.Outstr2 == "null" ? decimal.Zero : decimal.Parse(resultValidarProcedimiento.Outstr2);
                
                var response = new ValidarConsultaResponseDto
                {
                    Codigo = _parametrosConfig.ServicioConsulta.Cobertura,
                    Frecuencia = frecuencia,
                    MontoArs = montoCubierto,
                    MontoAfiliado = montoAfiliado,
                    MontoReclamado = montoCubierto + montoAfiliado
                };

                return Success(response);
            }

            return HandleErrors(resultValidarProcedimiento.Outnum1);
        }

        private ResponseDto<ValidarConsultaResponseDto> HandleErrors(string outnum1)
        {

            if (_errorCodes.ContainsKey(outnum1))
            {
                return Error(Convert.ToInt32(outnum1), _errorCodes[outnum1]);
            }
            return Error(StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
        }

        private bool EsValida(string resultado)
        {
            return RespuestaInfoxprocValidaCobertura.CoberturaValida == resultado;
        }
    }
}
