using AutoMapper;
using GestionAutorizaciones.Application.Asegurado.Common;
using GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado;
using GestionAutorizaciones.Application.Sesion.Common;
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
using GestionAutorizaciones.Application.Autorizaciones.Common;

namespace GestionAutorizaciones.Application.Autorizaciones.ObtenerDetalleAutorizacion
{
    public class ObtenerDetalleAutorizacionQueryHandler : IRequestHandler<ObtenerDetalleAutorizacionQuery, ResponseDto<ObtenerDetalleAutorizacionResponseDto>>
    {
        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IMapper _mapper;
        private readonly IAseguradoRepositorio _aseguradoRepositorio;
        private readonly IAutorizacionRepositorio _autorizacionRepositorio;

        public ObtenerDetalleAutorizacionQueryHandler(IMapper mapper, IAseguradoRepositorio aseguradoRepositorio,
            ISesionRepositorio sesionRepositorio, IAutorizacionRepositorio autorizacionRepositorio)
        {
            _mapper = mapper;
            _aseguradoRepositorio = aseguradoRepositorio;
            _sesionRepositorio = sesionRepositorio;
            _autorizacionRepositorio = autorizacionRepositorio;
        }

        public async Task<ResponseDto<ObtenerDetalleAutorizacionResponseDto>> Handle(ObtenerDetalleAutorizacionQuery request, CancellationToken cancellationToken)
        {
            try
            {
                AutorizacionLegacyDto autorizacionLegacy = ObtenerAutorizacionLegacy(request.NumeroAutorizacion);

                if (autorizacionLegacy == null)
                {
                    return new ResponseDto<ObtenerDetalleAutorizacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

                List<Reclamacion> resultReclamaciones
                    = (List<Reclamacion>)await _autorizacionRepositorio.ObtenerInformacionReclamaciones(request.Ano,
                    autorizacionLegacy.Compania, autorizacionLegacy.Ramo, autorizacionLegacy.Secuencial, request.CodigoPss);

                if (resultReclamaciones == null || resultReclamaciones.Count == 0)
                {
                    return new ResponseDto<ObtenerDetalleAutorizacionResponseDto>(null, StatusCodes.Status204NoContent, DescripcionRespuesta.NoContent);
                }

                OrigenDto origen = ObtenerOrigenPorRamo(resultReclamaciones.FirstOrDefault().Ramo);

                var companiaInfo = new CompaniaInfo
                {
                    Codigo = origen.Compania,
                    Nombre = origen.Descripcion
                };

                List<ProcedimientoDTO> procedimientosList = new List<ProcedimientoDTO>();
                try
                {
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

                }
                catch (Exception)
                {
                }

                var reclamacionFromDb = resultReclamaciones.FirstOrDefault();

                var reclamacionData = new ReclamacionDTO
                {
                    Compania = companiaInfo,
                    NumeroAutorizacion =
                    $"{reclamacionFromDb.Ano}-{reclamacionFromDb.Compania}-{reclamacionFromDb.Ramo}-{reclamacionFromDb.Secuencial}"
                };

                var obtenerDetalleAutorizacionData = new ObtenerDetalleAutorizacionResponseDto
                {
                    Reclamacion = reclamacionData,
                    Compania = reclamacionFromDb.Compania,
                    Ramo = reclamacionFromDb.Ramo,
                    Secuencial = reclamacionFromDb.Secuencial,
                    Fecha = reclamacionFromDb.FechaApertura,
                    CodigoEstado = reclamacionFromDb.Estatus,
                    NombreEstado = reclamacionFromDb.Descripcion,
                    Afiliado = null,
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

                try
                {
                    var resultOrigen = await _aseguradoRepositorio.ObtenerOrigenPlastico(reclamacionFromDb.NumeroPlastico);

                    if (resultOrigen != null)
                    {
                        var origenPlastico = ObtenerOrigenPorParametro(resultOrigen.Codigo);

                        if (origenPlastico.Codigo != 0)
                        {
                            var resultAfiliado = await _aseguradoRepositorio.ObtenerAfiliado(tipoId: TipoDocumento.Plastico,
                                identificacion: Convert.ToString(reclamacionFromDb.NumeroPlastico), compania: origenPlastico.Compania);

                            if (resultAfiliado != null)
                            {
                                AfiliadoDTO afiliado = _mapper.Map<AfiliadoDTO>(resultAfiliado);
                                afiliado.NumeroPlastico = reclamacionFromDb.NumeroPlastico;
                                try
                                {

                                    List<Nucleo> nucleo = (List<Nucleo>)await _aseguradoRepositorio.ObtenerNucleos(reclamacionFromDb.NumeroPlastico);

                                    if (nucleo != null)
                                    {
                                        List<Acompanante> acompanantes = _mapper.Map<List<Nucleo>, List<Acompanante>>(nucleo);
                                        afiliado.Acompanantes = acompanantes;
                                    }


                                }
                                catch (Exception) { }

                                try
                                {
                                    Telefono telefono = await _aseguradoRepositorio.ObtenerTelefono(reclamacionFromDb.NumeroPlastico);

                                    if (telefono != null)
                                    {
                                        afiliado.Telefono = telefono.NumeroTelefono;
                                    }

                                }
                                catch (Exception) { }

                                obtenerDetalleAutorizacionData.Afiliado = afiliado;

                            }

                        }

                    }

                }
                catch (Exception) { }

                return new ResponseDto<ObtenerDetalleAutorizacionResponseDto>(obtenerDetalleAutorizacionData, StatusCodes.Status200OK, DescripcionRespuesta.OK);

            }
            catch (Exception e)
            {
                return new ResponseDto<ObtenerDetalleAutorizacionResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }
        }
    }
}
