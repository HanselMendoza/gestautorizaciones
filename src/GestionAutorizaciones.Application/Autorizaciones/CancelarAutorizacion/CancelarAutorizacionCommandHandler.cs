using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.Domain.Entities;
using MediatR;
using Microsoft.AspNetCore.Http;
using System;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using static GestionAutorizaciones.Application.Common.Utils.Funciones;
using GestionAutorizaciones.Application.Sesion.Common;

namespace GestionAutorizaciones.Application.Autorizaciones.CancelarAutorizacion
{
    public class CancelarAutorizacionCommandHandler : IRequestHandler<CancelarAutorizacionCommand, ResponseDto<CancelarAutorizacionResponseDto>>
    {

        private readonly ISesionRepositorio _sesionRepositorio;

        public CancelarAutorizacionCommandHandler(ISesionRepositorio sesionRepositorio)
        {
            _sesionRepositorio = sesionRepositorio;
        }


        public async Task<ResponseDto<CancelarAutorizacionResponseDto>> Handle(CancelarAutorizacionCommand request, CancellationToken cancellationToken)
        {
            try
            {
                var resultValidarAfiliado = await _sesionRepositorio.Infoxproc(NombreOperacion.ValidarAsegurado, request.NumeroSesion,
                    Convert.ToString(request.NumeroPlastico), null, null, null);

                if (resultValidarAfiliado != null)
                {
                    if (resultValidarAfiliado.Outnum1 == RespuestaInfoxprocAfiliado.PlasticoNoExiste)
                    {
                        return new ResponseDto<CancelarAutorizacionResponseDto>(null,
                            int.Parse(RespuestaInfoxprocAfiliado.PlasticoNoExiste), MensajeInfoxproc.PlasticoNoExiste);
                    }

                    if (resultValidarAfiliado.Outnum1 == RespuestaInfoxprocAfiliado.PlasticoInvalidado)
                    {
                        return new ResponseDto<CancelarAutorizacionResponseDto>(null,
                            int.Parse(RespuestaInfoxprocAfiliado.PlasticoInvalidado), MensajeInfoxproc.PlasticoInvalidado);
                    }

                    if (resultValidarAfiliado.Outnum1 == RespuestaInfoxprocAfiliado.AseguradoValido)
                    {
                        AutorizacionLegacyDto autorizacionLegacy = ObtenerAutorizacionLegacy(request.NumeroAutorizacion);

                        if (autorizacionLegacy == null)
                        {
                            return new ResponseDto<CancelarAutorizacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                        }
                        var resultValidarReclamacion = await _sesionRepositorio.Infoxproc(NombreOperacion.ValidarReclamacion, request.NumeroSesion,
                            Convert.ToString(autorizacionLegacy.Secuencial), null, null, null, request.UsuarioIngresa);

                        if (resultValidarReclamacion.Outnum1 != RespuestaInfoxprocValidaReclamacion.ReclamacionValida)
                        {
                            return new ResponseDto<CancelarAutorizacionResponseDto>(null,
                                int.Parse(RespuestaInfoxprocValidaReclamacion.ReclamacionNoValida), MensajeInfoxproc.ErrorValidarReclamacion);
                        }

                        var resultEliminarReclamacion = await _sesionRepositorio.Infoxproc(NombreOperacion.EliminarReclamacion, request.NumeroSesion,
                            null, null, ReclamacionCodigoEstado.Anulada, (int) request.CodigoMotivo, request.UsuarioIngresa);

                        if (resultEliminarReclamacion.Outnum1 != RespuestaInfoxprocEliminarReclamacion.ReclamacionEliminada)
                        {
                            return new ResponseDto<CancelarAutorizacionResponseDto>(null,
                                int.Parse(RespuestaInfoxprocEliminarReclamacion.ErrorEliminarReclamacion), MensajeInfoxproc.ErrorEliminarReclamacion);
                        }


                        var resultCerrarSesion = await _sesionRepositorio.Infoxproc(NombreOperacion.CerrarSesion, request.NumeroSesion,
                            null, null, null, null);

                        if (resultCerrarSesion.Outnum1 != RespuestaInfoxprocCerrarSesion.SesionCerrada)
                        {
                            return new ResponseDto<CancelarAutorizacionResponseDto>(null,
                                int.Parse(resultCerrarSesion.Outnum1), MensajeInfoxproc.ErrorCerrarSesion);
                        }

                        var datosSession = new InfoSesion { Estatus = (int)EstadosSesion.Cancelada };
                        await _sesionRepositorio.ActualizarInfoSession(request.NumeroSesion, datosSession);


                        var resultData = new CancelarAutorizacionResponseDto { NumeroSesion = request.NumeroSesion };

                        return new ResponseDto<CancelarAutorizacionResponseDto>(resultData, StatusCodes.Status200OK, DescripcionRespuesta.OK);

                    }
                    else
                    {
                        return new ResponseDto<CancelarAutorizacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                    }

                }
                else
                {
                    return new ResponseDto<CancelarAutorizacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }
            }
            catch (Exception e)
            {
                return new ResponseDto<CancelarAutorizacionResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }

        }
    }
}