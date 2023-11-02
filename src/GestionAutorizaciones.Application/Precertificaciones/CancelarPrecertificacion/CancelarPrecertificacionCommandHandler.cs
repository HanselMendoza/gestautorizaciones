using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Precertificaciones.Common;
using MediatR;
using Microsoft.AspNetCore.Http;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using System.Threading.Tasks;
using System.Threading;
using System;

namespace GestionAutorizaciones.Application.Precertificaciones.CancelarPrecertificacion
{
    public class CancelarPrecertificacionCommandHandler : IRequestHandler<CancelarPrecertificacionCommand, ResponseDto<CancelarPrecertificacionResponseDto>>
    {
        private readonly IPrecertificacionRepositorio _precertificacionRepositorio;

        public CancelarPrecertificacionCommandHandler(IPrecertificacionRepositorio precertificacionRepositorio)
        {
            _precertificacionRepositorio = precertificacionRepositorio;
        }

        public async Task<ResponseDto<CancelarPrecertificacionResponseDto>> Handle(CancelarPrecertificacionCommand request, CancellationToken cancellationToken)
        {
            try
            {
                var resultValidar = await _precertificacionRepositorio.ValidarPrecertificacion(request.TipoPss,
                    request.CodigoPss, request.Compania, request.NumeroPrecertificacion);

                if (resultValidar != null && resultValidar.CodigoValidacion == RespuestaInfoxprocValidaPrecertificacion.PrecertificacionNoValida)
                {
                    return new ResponseDto<CancelarPrecertificacionResponseDto>(null, RespuestaInfoxprocValidaPrecertificacion.PrecertificacionNoValida,
                        MensajeInfoxproc.PrecertificacionNoValida);
                }

                var resultCancelar = await _precertificacionRepositorio.CancelarPrecertificacion(request.TipoPss, request.CodigoPss, request.Compania, request.NumeroPrecertificacion);
                if (resultCancelar.CodigoValidacion != 0)
                {
                    return new ResponseDto<CancelarPrecertificacionResponseDto>(null, StatusCodes.Status400BadRequest, MensajeInfoxproc.ErrorCancelarPrecertificacion);
                }

                return new ResponseDto<CancelarPrecertificacionResponseDto>(null, CodigoRespuesta.OK, MensajeInfoxproc.PrecertificacionCancelada);

            }
            catch (Exception e)
            {
                return new ResponseDto<CancelarPrecertificacionResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }
        }
    }
}
