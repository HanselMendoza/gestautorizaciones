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
using GestionAutorizaciones.Domain.Entities;

namespace GestionAutorizaciones.Application.Procedimientos.ValidarProcedimiento

{
    public class ValidarProcedimientoCommandHandler : BaseHandler<ValidarProcedimientoCommand, ValidarProcedimientoResponseDto>
    {
        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IProcedimientoRepositorio _procedimientoRepositorio;
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


        public ValidarProcedimientoCommandHandler(ISesionRepositorio sesionRepositorio,
            IProcedimientoRepositorio procedimientoRepositorio)
        {
            _sesionRepositorio = sesionRepositorio;
            _procedimientoRepositorio = procedimientoRepositorio;
        }

        public async override Task<ResponseDto<ValidarProcedimientoResponseDto>> Handle(ValidarProcedimientoCommand request, CancellationToken cancellationToken)
        {
            var prefijo = request.TipoServicio.ToString("0000");
            var cobertura = $"{ prefijo + request.CodigoProcedimiento}";

            var serTipCob = new ServicioTipoCobertura(cobertura);

            SalidaEstandar resultValidarReglas = await _procedimientoRepositorio.ValidarPasaReglasCobertura(request.NumeroSesion, serTipCob.Servicio, request.CodigoProcedimiento);
            var aplicaValidacion = resultValidarReglas.Resultado == RespuestaInfoxprocValidaCobertura.CoberturaValida &&
                    resultValidarReglas.Aplica.Value;
            if (!aplicaValidacion)
            {
                return Error(StatusCodes.Status400BadRequest, MensajeInfoxproc.CoberturaNoAplicaTipoServicio);
            }

            var monto = Convert.ToString(request.Monto);

            var resultValidarProcedimiento = await _sesionRepositorio.Infoxproc(NombreOperacion.ValidarCobertura, request.NumeroSesion,
                cobertura, monto, request.Frecuencia, null, request.UsuarioRegistra);


            if (resultValidarProcedimiento.Outnum1 == RespuestaInfoxprocValidaCobertura.CoberturaValida)
            {
                var outstr2 = string.IsNullOrWhiteSpace(resultValidarProcedimiento.Outstr2) || resultValidarProcedimiento.Outstr2 == "null" ? decimal.Zero : decimal.Parse(resultValidarProcedimiento.Outstr2);
                var response = new ValidarProcedimientoResponseDto
                {
                    Codigo = request.CodigoProcedimiento,
                    Frecuencia = request.Frecuencia,
                    MontoArs = decimal.Parse(resultValidarProcedimiento.Outstr1),
                    MontoAfiliado = outstr2,
                    MontoReclamado = request.Monto == null || request.Monto == 0 ? decimal.Parse(resultValidarProcedimiento.Outstr1) + outstr2 : request.Monto
                };

                return Success(response);
            }

            if (_errorCodes.ContainsKey(resultValidarProcedimiento.Outnum1))
            {
                return Error(Convert.ToInt32(resultValidarProcedimiento.Outnum1),
                    _errorCodes[resultValidarProcedimiento.Outnum1]);
            }
            return Error(StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);

        }
    }
}
