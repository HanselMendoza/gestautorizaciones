using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Precertificaciones.Common;
using GestionAutorizaciones.Domain.Entities;
using MediatR;
using Microsoft.AspNetCore.Http;
using System;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;

namespace GestionAutorizaciones.Application.Precertificaciones.ConfirmarPrecertificacion
{
    public class ConfirmarPrecertificacionCommandHandler : IRequestHandler<ConfirmarPrecertificacionCommand, ResponseDto<ConfirmarPrecertificacionResponseDto>>
    {

        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IPrecertificacionRepositorio _precertificacionRepositorio;

        public ConfirmarPrecertificacionCommandHandler(ISesionRepositorio sesionRepositorio,
            IPrecertificacionRepositorio precertificacionRepositorio)
        {
            _sesionRepositorio = sesionRepositorio;
            _precertificacionRepositorio = precertificacionRepositorio;
        }

        public async Task<ResponseDto<ConfirmarPrecertificacionResponseDto>> Handle(ConfirmarPrecertificacionCommand request, CancellationToken cancellationToken)
        {
            try
            {
                InfoSesion resultInfoSesionPss = await _sesionRepositorio.ObtenerInfoSesion(request.NumeroSesion);

                if (resultInfoSesionPss == null || resultInfoSesionPss.CodigoPss == null)
                {
                    return new ResponseDto<ConfirmarPrecertificacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

                var resultValidar = await _precertificacionRepositorio.ValidarPrecertificacion(resultInfoSesionPss.TipoPss,
                    long.Parse(resultInfoSesionPss.CodigoPss), request.Compania, request.NumeroPrecertificacion);

                if (resultValidar != null && resultValidar.CodigoValidacion == RespuestaInfoxprocValidaPrecertificacion.PrecertificacionNoValida)
                {
                    return new ResponseDto<ConfirmarPrecertificacionResponseDto>(null, RespuestaInfoxprocValidaPrecertificacion.PrecertificacionNoValida,
                        MensajeInfoxproc.PrecertificacionNoValida);
                }

                if (resultValidar != null && resultValidar.CodigoValidacion == RespuestaInfoxprocValidaPrecertificacion.EstadoInvalido)
                {
                    return new ResponseDto<ConfirmarPrecertificacionResponseDto>(null, RespuestaInfoxprocValidaPrecertificacion.EstadoInvalido,
                        MensajeInfoxproc.EstadoInvalido);
                }

                var data = new ConfirmarPrecertificacionResponseDto
                {
                    NumeroSesion = request.NumeroSesion,
                    NumeroAutorizacion = resultValidar.NumeroAutorizacion,
                    TipoAutorizacion = resultValidar.TipoAutorizacion
                };

                if (resultValidar != null && resultValidar.CodigoValidacion == RespuestaInfoxprocValidaPrecertificacion.PrecertificacionYaConvertida)
                {
                    return new ResponseDto<ConfirmarPrecertificacionResponseDto>(data, RespuestaInfoxprocValidaPrecertificacion.PrecertificacionYaConvertida,
                        MensajeInfoxproc.PrecertificacionYaConvertida);
                }

                if (resultValidar != null && resultValidar.CodigoValidacion == RespuestaInfoxprocValidaPrecertificacion.PrecertificacionValida)
                {
                    var resultActivar = await _precertificacionRepositorio.ActivarPrecertificacion(request.NumeroSesion, request.NumeroPrecertificacion, request.UsuarioRegistra);
                    if (resultActivar.CodigoValidacion != 0)
                    {
                        return new ResponseDto<ConfirmarPrecertificacionResponseDto>(null, StatusCodes.Status400BadRequest, MensajeInfoxproc.ErrorActivarPrecertificacion);
                    }
                    
                    data.NumeroAutorizacion = resultActivar.NumeroAutorizacion;
                    data.TipoAutorizacion = resultActivar.TipoAutorizacion;
                    return new ResponseDto<ConfirmarPrecertificacionResponseDto>(data, CodigoRespuesta.OK, DescripcionRespuesta.OK);
                }
                else
                {
                    return new ResponseDto<ConfirmarPrecertificacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

            }
            catch (Exception e)
            {
                return new ResponseDto<ConfirmarPrecertificacionResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }

        }
    }
}