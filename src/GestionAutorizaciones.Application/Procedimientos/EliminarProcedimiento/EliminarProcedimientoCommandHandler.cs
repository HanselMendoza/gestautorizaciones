using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Domain.Entities;
using MediatR;
using Microsoft.AspNetCore.Http;
using System;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using System.Linq;

namespace GestionAutorizaciones.Application.Procedimientos.EliminarProcedimiento
{
    public class EliminarProcedimientoCommandHandler : IRequestHandler<EliminarProcedimientoCommand, ResponseDto<EliminarProcedimientoResponseDto>>
    {
        private readonly ISesionRepositorio _sesionRepositorio;

        public EliminarProcedimientoCommandHandler(ISesionRepositorio sesionRepositorio)
        {
            _sesionRepositorio = sesionRepositorio;
        }

        public async Task<ResponseDto<EliminarProcedimientoResponseDto>> Handle(EliminarProcedimientoCommand request, CancellationToken cancellationToken)
        {
            try
            {
                if (request.Procedimiento != null && request.Procedimiento != 0)
                {
                    var resultEliminarProcedimiento = await _sesionRepositorio.Infoxproc(NombreOperacion.EliminarCobertura, request.NumeroSesion,
                         null, null, int.Parse(Convert.ToString(request.Procedimiento)), null);

                    if (resultEliminarProcedimiento.Outnum1 != RespuestaInfoxprocEliminarCobertura.CoberturaEliminada)
                    {
                        return new ResponseDto<EliminarProcedimientoResponseDto>(null, int.Parse(resultEliminarProcedimiento.Outnum1),
                            MensajeInfoxproc.ErrorEliminarCobertura);
                    }

                    var eliminarProcedimientoResponse = new EliminarProcedimientoResponseDto
                    {
                        NumeroSesion = request.NumeroSesion,
                        Procedimiento = request.Procedimiento
                    };
                    return new ResponseDto<EliminarProcedimientoResponseDto>(eliminarProcedimientoResponse, StatusCodes.Status200OK, DescripcionRespuesta.OK);
                }
                else
                {
                    var  detalleReclamacionList = await _sesionRepositorio.ObtenerDetalleReclamacion(request.NumeroSesion);

                    DetalleReclamacion ultimoProcedimiento = detalleReclamacionList.LastOrDefault();

                    if (ultimoProcedimiento == null)
                    {
                        return new ResponseDto<EliminarProcedimientoResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                    }

                    var resultEliminarProcedimiento = await _sesionRepositorio.Infoxproc(NombreOperacion.EliminarCobertura, request.NumeroSesion,
                        null, null, int.Parse(ultimoProcedimiento.Procedimiento), null);

                    if (resultEliminarProcedimiento.Outnum1 != RespuestaInfoxprocEliminarCobertura.CoberturaEliminada)
                    {
                        return new ResponseDto<EliminarProcedimientoResponseDto>(null, int.Parse(resultEliminarProcedimiento.Outnum1),
                            MensajeInfoxproc.ErrorEliminarCobertura);
                    }

                    var eliminarProcedimientoResponse = new EliminarProcedimientoResponseDto
                    {
                        NumeroSesion = request.NumeroSesion,
                        Procedimiento = request.Procedimiento
                    };
                    return new ResponseDto<EliminarProcedimientoResponseDto>(eliminarProcedimientoResponse, StatusCodes.Status200OK, DescripcionRespuesta.OK);

                }

            }
            catch (Exception e)
            {
                return new ResponseDto<EliminarProcedimientoResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }

        }
    }
}
