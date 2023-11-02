using GestionAutorizaciones.Application.Asegurado.Common;
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
using static GestionAutorizaciones.Application.Common.Utils.Funciones;
using System.Linq;

namespace GestionAutorizaciones.Application.Sesion.CerrarSesion
{
    public class CerrarSesionCommandHandler : IRequestHandler<CerrarSesionCommand, ResponseDto<CerrarSesionResponseDto>>
    {
        private readonly ISesionRepositorio _sesionRepositorio;

        public CerrarSesionCommandHandler(ISesionRepositorio gestionAutorizacionRepositorio)
        {
            _sesionRepositorio = gestionAutorizacionRepositorio;
        }

        public async Task<ResponseDto<CerrarSesionResponseDto>> Handle(CerrarSesionCommand request, CancellationToken cancellationToken)
        {
            try
            {
                var estadoReclamacion = EstadoReclamacion.EstadoAperturado;

                if (request.PreAutorizar)
                {
                    estadoReclamacion = EstadoReclamacion.EstadoPreAutorizado;
                }

                InfoSesion resultInfoSesionPss = await _sesionRepositorio.ObtenerInfoSesion(request.NumeroSesion);

                if (resultInfoSesionPss == null || resultInfoSesionPss.CodigoPss == null)
                {
                    return new ResponseDto<CerrarSesionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

                var resultCerrarReclamacion = await _sesionRepositorio.Infoxproc(NombreOperacion.CerrarReclamacion,
                    request.NumeroSesion, resultInfoSesionPss.CodigoPss, estadoReclamacion, null, null);

                if (resultCerrarReclamacion.Outnum1 != RespuestaInfoxprocCerrarReclamacion.ReclamacionCerrada)
                {
                    return new ResponseDto<CerrarSesionResponseDto>(null, int.Parse(resultCerrarReclamacion.Outnum1),
                        MensajeInfoxproc.ErrorCerrarReclamacion);
                }

                decimal montoArs = decimal.Parse(resultCerrarReclamacion.Outstr1);
                decimal montoAfiliado = decimal.Parse(resultCerrarReclamacion.Outstr2);
                decimal montoReclamado = montoArs + montoAfiliado;

                if (request.EsARL)
                {
                    try
                    {
                        await _sesionRepositorio.MarcarComoArl(request.NumeroSesion);
                    }
                    catch (Exception) { }
                }

                var resultCerrarSesion = await _sesionRepositorio.Infoxproc(NombreOperacion.CerrarSesion,
                    request.NumeroSesion, null, null, null, null);

                if (resultCerrarSesion.Outnum1 != RespuestaInfoxprocCerrarSesion.SesionCerrada)
                {
                    return new ResponseDto<CerrarSesionResponseDto>(null, int.Parse(resultCerrarReclamacion.Outnum1),
                        MensajeInfoxproc.ErrorCerrarSesion);
                }

                var datosSession = new InfoSesion { Estatus = (int)EstadosSesion.Enviada };
                await _sesionRepositorio.ActualizarInfoSession(request.NumeroSesion, datosSession);

                var detalleReclamacionList = await _sesionRepositorio.ObtenerDetalleReclamacion(request.NumeroSesion);
                var detalleReclamacion = detalleReclamacionList.FirstOrDefault();
                
                var secuencial = detalleReclamacion.Secuencial;
                var ramo = detalleReclamacion.Ramo;
                var origen = ObtenerOrigenPorRamo(int.Parse(ramo.ToString()));
                var numeroAutorizacion = $"{origen.Prefijo}{ramo.Value}-{secuencial.Value}";

                var resultData = new CerrarSesionResponseDto
                {
                    Compania = new CerrarSesionResponseDto.CompaniaDetalle
                    {
                        Codigo = origen.Compania,
                        Nombre = origen.Descripcion
                    },

                    Autorizacion = new CerrarSesionResponseDto.AutorizacionDetalle
                    {
                        NumeroAutorizacion = numeroAutorizacion,
                        Ramo = ramo,
                        Secuencial = secuencial,
                        Estado = estadoReclamacion,
                        MontoReclamado = montoReclamado,
                        MontoARS = montoArs,
                        MontoAfiliado = montoAfiliado
                    }
                };

                return new ResponseDto<CerrarSesionResponseDto>(resultData, StatusCodes.Status200OK, DescripcionRespuesta.OK);
            }
            catch (Exception e)
            {
                return new ResponseDto<CerrarSesionResponseDto>(null, StatusCodes.Status500InternalServerError,
                    e.StackTrace);
            }
        }
    }
}