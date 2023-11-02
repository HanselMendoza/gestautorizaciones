using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Domain.Entities;
using MediatR;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using static GestionAutorizaciones.Application.Common.Utils.Funciones;
using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Autorizaciones.Common;

namespace GestionAutorizaciones.Application.Sesion.ReactivarSesion
{
    public class ReactivarSesionCommandHandler : IRequestHandler<ReactivarSesionCommand, ResponseDto<ReactivarSesionResponseDto>>
    {

        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IAutorizacionRepositorio _autorizacionRepositorio;

        public ReactivarSesionCommandHandler(ISesionRepositorio sesionRepositorio,
            IAutorizacionRepositorio autorizacionRepositorio)
        {
            _sesionRepositorio = sesionRepositorio;
            _autorizacionRepositorio = autorizacionRepositorio;
        }

        public async Task<ResponseDto<ReactivarSesionResponseDto>> Handle(ReactivarSesionCommand request, CancellationToken cancellationToken)
        {
            try
            {
                var ano = request.Anio ?? DateTime.Now.Year;

                AutorizacionLegacyDto autorizacionLegacy = ObtenerAutorizacionLegacy(request.NumeroAutorizacion);

                if (autorizacionLegacy == null)
                {
                    return new ResponseDto<ReactivarSesionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

                Domain.Entities.Sesion resultSesion = await _sesionRepositorio.ReactivarSesion(ano,
                    autorizacionLegacy.Compania, autorizacionLegacy.Ramo, autorizacionLegacy.Secuencial);

                if (resultSesion == null || resultSesion.NumeroSesion == 0)
                {
                    return new ResponseDto<ReactivarSesionResponseDto>(null, int.Parse(resultSesion.Resultado), resultSesion?.Mensaje);
                }

                List<Reclamacion> resultReclamaciones
                    = (List<Reclamacion>)await _autorizacionRepositorio.ObtenerInformacionReclamaciones(ano,
                    autorizacionLegacy.Compania, autorizacionLegacy.Ramo, autorizacionLegacy.Secuencial, request.CodigoPss);

                if (resultReclamaciones == null || resultReclamaciones.Count == 0)
                {
                    return new ResponseDto<ReactivarSesionResponseDto>(null, StatusCodes.Status204NoContent, DescripcionRespuesta.NoContent);
                }

                OrigenDto origen = ObtenerOrigenPorRamo(resultReclamaciones.FirstOrDefault().Ramo);

                var companiaInfo = new CompaniaInfo
                {
                    Codigo = origen.Compania,
                    Nombre = origen.Descripcion
                };

                List<ProcedimientoDTO> procedimientosList =
                    new List<ProcedimientoDTO>();

                foreach (Reclamacion reclamacion in resultReclamaciones)
                {
                    procedimientosList.Add(new ProcedimientoDTO
                    {
                        Codigo = reclamacion.Cobertura,
                        Nombre = reclamacion.DescripcionCobertura,
                        Frecuencia = reclamacion.Frecuencia,
                        MontoReclamado = reclamacion.MontoReclamado,
                        MontoARS = reclamacion.MontoPagado,
                        MontoAfiliado = reclamacion.MontoAsegurado
                    });
                }

                var reclamacionFromDb = resultReclamaciones.FirstOrDefault();

                var reclamacionData = new ReclamacionDTO
                {
                    Compania = companiaInfo,
                    NumeroAutorizacion =
                    $"{reclamacionFromDb.Ano}-{reclamacionFromDb.Compania}-{reclamacionFromDb.Ramo}-{reclamacionFromDb.Secuencial}"
                };

                var autorizacionData = new Autorizacion
                {
                    Reclamacion = reclamacionData,
                    Compania = reclamacionFromDb.Compania,
                    Ramo = reclamacionFromDb.Ramo,
                    Secuencial = reclamacionFromDb.Secuencial,
                    Fecha = reclamacionFromDb.FechaApertura,
                    CodigoEstado = reclamacionFromDb.Estatus,
                    NombreEstado = reclamacionFromDb.Descripcion,
                    CodigoPss = reclamacionFromDb.Reclamante,
                    NombrePss = reclamacionFromDb.Nombre,
                    TipoPss = reclamacionFromDb.TipoReclamante,
                    UsuarioIngreso = reclamacionFromDb.UsuarioIngreso,
                    TotalReclamado = reclamacionFromDb.MontoReclamado,
                    TotalARS = reclamacionFromDb.MontoPagado,
                    TotalAfiliado = reclamacionFromDb.MontoAsegurado,
                    CodigoServicio = reclamacionFromDb.TipoServicio,
                    Procedimientos = procedimientosList
                };

                var reactivarSesionResponse = new ReactivarSesionResponseDto
                {
                    NumeroSesion = resultSesion.NumeroSesion,
                    Autorizacion = autorizacionData
                };

                return new ResponseDto<ReactivarSesionResponseDto>(reactivarSesionResponse, CodigoRespuesta.OK, DescripcionRespuesta.OK);

            }
            catch (Exception e)
            {
                return new ResponseDto<ReactivarSesionResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }
        }
    }
}
