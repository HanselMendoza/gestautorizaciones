using AutoMapper;
using GestionAutorizaciones.Application.Asegurado.Common;
using GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado;
using GestionAutorizaciones.Application.Autorizaciones.ObtenerDetalleAutorizacion;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Precertificaciones.Common;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Application.Sesion.Common;
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

namespace GestionAutorizaciones.Application.Precertificaciones.ObtenerDetallePrecertificacion
{
    public class ObtenerDetallePrecertificacionQueryHandler : IRequestHandler<ObtenerDetallePrecertificacionQuery, ResponseDto<ObtenerDetallePrecertificacionResponseDto>>
    {

        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IPrecertificacionRepositorio _precertificacionRepositorio;
        private readonly IMapper _mapper;
        private readonly IAseguradoRepositorio _aseguradoRepositorio;
        public ObtenerDetallePrecertificacionQueryHandler(IMapper mapper, 
            IAseguradoRepositorio aseguradoRepositorio, ISesionRepositorio sesionRepositorio,
            IPrecertificacionRepositorio precertificacionRepositorio)
        {
            _mapper = mapper;
            _aseguradoRepositorio = aseguradoRepositorio;
            _sesionRepositorio = sesionRepositorio;
            _precertificacionRepositorio = precertificacionRepositorio;
        }

        public async Task<ResponseDto<ObtenerDetallePrecertificacionResponseDto>> Handle(ObtenerDetallePrecertificacionQuery request, CancellationToken cancellationToken)
        {

            try
            {

                InfoSesion resultInfoSesionPss = await _sesionRepositorio.ObtenerInfoSesion(request.NumeroSesion);

                if (resultInfoSesionPss == null || resultInfoSesionPss.CodigoPss == null)
                {
                    return new ResponseDto<ObtenerDetallePrecertificacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

                List<Precertificacion> resultDatosPrecertificacion = (List<Precertificacion>)await _precertificacionRepositorio.ObtenerDatosPrecertificacion(resultInfoSesionPss.TipoPss,
                    long.Parse(resultInfoSesionPss.CodigoPss), request.Compania, request.NumeroPrecertificacion);

                if (resultDatosPrecertificacion == null || resultDatosPrecertificacion.Count == 0)
                {
                    return new ResponseDto<ObtenerDetallePrecertificacionResponseDto>(null, StatusCodes.Status204NoContent, DescripcionRespuesta.NoContent);
                }

                OrigenDto origen = ObtenerOrigenPorRamo(int.Parse(resultDatosPrecertificacion.FirstOrDefault().Ramo.ToString()));
                var companiaData = new CompaniaInfoDto
                {
                    Codigo = origen.Compania,
                    Nombre = origen.Descripcion
                };

                List<ProcedimientoDTO> procedimientosList = new List<ProcedimientoDTO>();
                try
                {
                    foreach (Precertificacion precertificacion in resultDatosPrecertificacion)
                    {

                        procedimientosList.Add(new ProcedimientoDTO
                        {
                            Codigo = precertificacion.Cobertura,
                            Nombre = precertificacion.DescripcionCobertura,
                            Frecuencia = precertificacion.Frecuencia,
                            MontoReclamado = precertificacion.MontoReclamado,
                            MontoARS = precertificacion.MontoPagado,
                            MontoAfiliado = precertificacion.MontoPagadoAfiliado
                        });

                    }

                }
                catch (Exception)
                {
                }

                Precertificacion precertificacionFromDb = resultDatosPrecertificacion.FirstOrDefault();

                var precertificacionData = new PrecertificacionDTO
                {
                    CompaniaInfo = companiaData,
                    NumeroPrecertificacion = request.NumeroPrecertificacion,
                    Compania = precertificacionFromDb.Compania,
                    Ramo = precertificacionFromDb.Ramo,
                    Secuencial = precertificacionFromDb.Secuencial,
                    Fecha = precertificacionFromDb.FechaIngreso,
                    CodigoEstado = precertificacionFromDb.Estatus,
                    NombreEstado = precertificacionFromDb.DescripcionEstatus,
                    CodigoPss = precertificacionFromDb.CodigoPss,
                    NombrePss = precertificacionFromDb.NombrePss,
                    UsuarioIngreso = precertificacionFromDb.UsuarioIngreso,
                    TotalReclamado = precertificacionFromDb.MontoReclamado,
                    TotalARS = precertificacionFromDb.MontoPagado,
                    TotalAfiliado = precertificacionFromDb.MontoPagadoAfiliado,
                    Afiliado = null,
                    Procedimientos = procedimientosList

                };

                try
                {
                    var resultOrigen = await _aseguradoRepositorio.ObtenerOrigenPlastico(long.Parse(precertificacionFromDb.NumeroPlastico.ToString()));

                    if (resultOrigen != null)
                    {
                        var origenPlastico = ObtenerOrigenPorParametro(resultOrigen.Codigo);

                        if (origenPlastico.Codigo != 0)
                        {
                            var resultAfiliado = await _aseguradoRepositorio.ObtenerAfiliado(tipoId: TipoDocumento.Plastico,
                                identificacion: Convert.ToString(precertificacionFromDb.NumeroPlastico), compania: origenPlastico.Compania);

                            if (resultAfiliado != null)
                            {
                                AfiliadoDTO afiliado = _mapper.Map<AfiliadoDTO>(resultAfiliado);
                                afiliado.NumeroPlastico = precertificacionFromDb.NumeroPlastico;

                                try
                                {

                                    List<Nucleo> nucleo = (List<Nucleo>)await _aseguradoRepositorio.ObtenerNucleos(long.Parse(precertificacionFromDb.NumeroPlastico.ToString()));

                                    if (nucleo != null)
                                    {
                                        List<Acompanante> acompanantes = _mapper.Map<List<Nucleo>, List<Acompanante>>(nucleo);
                                        afiliado.Acompanantes = acompanantes;
                                    }


                                }
                                catch (Exception) { }

                                try
                                {
                                    Telefono telefono = await _aseguradoRepositorio.ObtenerTelefono(long.Parse(precertificacionFromDb.NumeroPlastico.ToString()));

                                    if (telefono != null)
                                    {
                                        afiliado.Telefono = telefono.NumeroTelefono;
                                    }

                                }
                                catch (Exception) { }

                                precertificacionData.Afiliado = afiliado;

                            }

                        }

                    }

                }
                catch (Exception) { }

                var precertificacionResponse = new ObtenerDetallePrecertificacionResponseDto
                {
                    Precertificacion = precertificacionData
                };

                return new ResponseDto<ObtenerDetallePrecertificacionResponseDto>(precertificacionResponse, CodigoRespuesta.OK, DescripcionRespuesta.OK);


            }
            catch (Exception e)
            {
                return new ResponseDto<ObtenerDetallePrecertificacionResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }
        }
    }
}
