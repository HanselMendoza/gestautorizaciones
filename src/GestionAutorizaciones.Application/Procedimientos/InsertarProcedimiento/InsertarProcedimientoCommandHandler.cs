using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Domain.Entities;
using GestionAutorizaciones.Domain.Entities.Enums;
using MediatR;
using Microsoft.AspNetCore.Http;
using System;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;

namespace GestionAutorizaciones.Application.Procedimientos.InsertarProcedimiento
{
    public class InsertarProcedimientoCommandHandler : IRequestHandler<InsertarProcedimientoCommand, ResponseDto<InsertarProcedimientoResponseDto>>
    {
        private readonly ISesionRepositorio _sesionRepositorio;

        public InsertarProcedimientoCommandHandler(ISesionRepositorio sesionRepositorio)
        {
            _sesionRepositorio = sesionRepositorio;
        }

        public async Task<ResponseDto<InsertarProcedimientoResponseDto>> Handle(InsertarProcedimientoCommand request, CancellationToken cancellationToken)
        {
            try
            {
                InfoSesion resultInfoSesionPss = await _sesionRepositorio.ObtenerInfoSesion(request.NumeroSesion);

                if (resultInfoSesionPss == null || resultInfoSesionPss.CodigoPss == null)
                {
                    return new ResponseDto<InsertarProcedimientoResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

                if (resultInfoSesionPss.DescripcionEstatus == DescripcionEstatusSesion.Abierta)
                {
                    var resultOpenReclamacion = await _sesionRepositorio.Infoxproc(NombreOperacion.AbrirReclamacion,
                        request.NumeroSesion, resultInfoSesionPss.CodigoPss, null, null, null, request.UsuarioRegistra);
                    if(resultOpenReclamacion.Outnum1 == RespuestaInfoxprocAbrirReclamacion.ReclamacionAbierta)
                    {
                        var datosSession = new InfoSesion { Estatus = (int)EstadosSesion.Pendiente };
                        await _sesionRepositorio.ActualizarInfoSession(request.NumeroSesion, datosSession);
                    }

                    if (resultOpenReclamacion.Outnum1 == RespuestaInfoxprocAbrirReclamacion.ErrorAbrirReclamacion)
                    {
                        return new ResponseDto<InsertarProcedimientoResponseDto>(null,
                            int.Parse(RespuestaInfoxprocAbrirReclamacion.ErrorAbrirReclamacion), MensajeInfoxproc.ErrorAbrirReclamacion);
                    }
                }

                RespuestaInfoxProc resultInsertarProcedimiento = null;

                var frecuencia = request.Frecuencia ?? 0;
                frecuencia = frecuencia == 0 ? ParametrosFijos.Frecuencia : frecuencia;

                resultInsertarProcedimiento = await _sesionRepositorio.Infoxproc(NombreOperacion.InsertarCobertura,
                    request.NumeroSesion, null, null, frecuencia, null);

                if (resultInsertarProcedimiento.Outnum1 == RespuestaInfoxprocInsertarCobertura.CoberturaInsertada)
                {

                    InsertarProcedimientoResponseDto response = new InsertarProcedimientoResponseDto
                    {
                        NumeroSesion = request.NumeroSesion
                    };
                    return new ResponseDto<InsertarProcedimientoResponseDto>(response, StatusCodes.Status200OK, DescripcionRespuesta.OK);
                }
                else
                {
                    return new ResponseDto<InsertarProcedimientoResponseDto>(null,
                        int.Parse(RespuestaInfoxprocInsertarCobertura.ErrorInsertarCobertura), MensajeInfoxproc.ErrorInsertarCobertura);
                }


            }
            catch (Exception e)
            {
                return new ResponseDto<InsertarProcedimientoResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);

            }

        }
    }
}
