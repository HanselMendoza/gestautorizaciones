using GestionAutorizaciones.Application.Common.Dtos;
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

namespace GestionAutorizaciones.Application.Autorizaciones.ConciliarAutorizacion
{
    public class ConciliarAutorizacionCommandHandler : IRequestHandler<ConciliarAutorizacionCommand, ResponseDto<ConciliarAutorizacionResponseDto>>
    {

        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IPrestadorRepositorio _prestadorRepositorio;
        public ConciliarAutorizacionCommandHandler(IPrestadorRepositorio prestadorRepositorio,
             ISesionRepositorio sesionRepositorio)
        {
            _prestadorRepositorio = prestadorRepositorio;
            _sesionRepositorio = sesionRepositorio;
        }

        public async Task<ResponseDto<ConciliarAutorizacionResponseDto>> Handle(ConciliarAutorizacionCommand request, CancellationToken cancellationToken)
        {
            try
            {

                if (request.Detalle == null || request.Detalle.Count == 0)
                {
                    return new ResponseDto<ConciliarAutorizacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }
                InfoSesion resultInfoSesionPss = await _sesionRepositorio.ObtenerInfoSesion(request.NumeroSesion);

                if (resultInfoSesionPss == null || resultInfoSesionPss.CodigoPss == null)
                {
                    return new ResponseDto<ConciliarAutorizacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

                List<ReclamacionPss> resultAutorizaciones = (List<ReclamacionPss>)await _prestadorRepositorio.ObtenerReclamacionesPss(resultInfoSesionPss.TipoPss,
                    long.Parse(resultInfoSesionPss.CodigoPss), request.FechaInicio, request.FechaFin, null, null, null, null, null);

                if (resultAutorizaciones == null || resultAutorizaciones.Count == 0)
                {
                    return new ResponseDto<ConciliarAutorizacionResponseDto>(null, StatusCodes.Status204NoContent, DescripcionRespuesta.NoContent);

                }

                List<ErrorDetalle> errorlist = new List<ErrorDetalle>();

                foreach (DetalleAutorizacion detalleAutorizacion in request.Detalle)
                {

                    List<ReclamacionPss> resultFilter = resultAutorizaciones.Where(o => o.Ano == detalleAutorizacion.Ano
                    && o.Compania == detalleAutorizacion.Compania
                    && o.Ramo == detalleAutorizacion.Ramo
                    && o.Secuencial == detalleAutorizacion.Secuencial).ToList();

                    var autorizacionDb = resultFilter.FirstOrDefault();

                    if (autorizacionDb != null)
                    {
                        if (autorizacionDb.NumeroPlastico != detalleAutorizacion.NumeroPlastico)
                        {
                            errorlist.Add(new ErrorDetalle
                            {
                                Error = new Error { Codigo = CodigoErrorConciliacion.PlasticoNoCoincide, Descripcion = MensajeErrorConciliacion.PlasticoNoCoincide },
                                Ano = detalleAutorizacion.Ano,
                                Compania = detalleAutorizacion.Compania,
                                Ramo = detalleAutorizacion.Ramo,
                                Secuencial = detalleAutorizacion.Secuencial,
                                Fecha = detalleAutorizacion.Fecha,
                                Estado = detalleAutorizacion.Estado,
                                NumeroPlastico = detalleAutorizacion.NumeroPlastico,
                                MontoARS = detalleAutorizacion.MontoARS,
                                MontoAsegurado = detalleAutorizacion.MontoAseg,
                                MontoReclamado = detalleAutorizacion.MontoReclamado

                            });
                        }

                        if (autorizacionDb.Estatus != detalleAutorizacion.Estado)
                        {
                            errorlist.Add(new ErrorDetalle
                            {
                                Error = new Error { Codigo = CodigoErrorConciliacion.EstadosNoCoinciden, Descripcion = MensajeErrorConciliacion.EstadosNoCoinciden },
                                Ano = detalleAutorizacion.Ano,
                                Compania = detalleAutorizacion.Compania,
                                Ramo = detalleAutorizacion.Ramo,
                                Secuencial = detalleAutorizacion.Secuencial,
                                Fecha = detalleAutorizacion.Fecha,
                                Estado = detalleAutorizacion.Estado,
                                NumeroPlastico = detalleAutorizacion.NumeroPlastico,
                                MontoARS = detalleAutorizacion.MontoARS,
                                MontoAsegurado = detalleAutorizacion.MontoAseg,
                                MontoReclamado = detalleAutorizacion.MontoReclamado

                            });
                        }

                        if (autorizacionDb.MontoAsegurado != detalleAutorizacion.MontoAseg
                            || autorizacionDb.MontoPagado != detalleAutorizacion.MontoARS
                            || autorizacionDb.MontoReclamado != detalleAutorizacion.MontoReclamado)
                        {
                            errorlist.Add(new ErrorDetalle
                            {
                                Error = new Error { Codigo = CodigoErrorConciliacion.MontosNoCoinciden, Descripcion = MensajeErrorConciliacion.MontosNoCoinciden },
                                Ano = detalleAutorizacion.Ano,
                                Compania = detalleAutorizacion.Compania,
                                Ramo = detalleAutorizacion.Ramo,
                                Secuencial = detalleAutorizacion.Secuencial,
                                Fecha = detalleAutorizacion.Fecha,
                                Estado = detalleAutorizacion.Estado,
                                NumeroPlastico = detalleAutorizacion.NumeroPlastico,
                                MontoARS = detalleAutorizacion.MontoARS,
                                MontoAsegurado = detalleAutorizacion.MontoAseg,
                                MontoReclamado = detalleAutorizacion.MontoReclamado

                            });
                        }

                    }
                    else
                    {
                        errorlist.Add(new ErrorDetalle
                        {
                            Error = new Error { Codigo = CodigoErrorConciliacion.AutorizacionNoExiste, Descripcion = MensajeErrorConciliacion.AutorizacionNoExiste },
                            Ano = detalleAutorizacion.Ano,
                            Compania = detalleAutorizacion.Compania,
                            Ramo = detalleAutorizacion.Ramo,
                            Secuencial = detalleAutorizacion.Secuencial,
                            Fecha = detalleAutorizacion.Fecha,
                            Estado = detalleAutorizacion.Estado,
                            NumeroPlastico = detalleAutorizacion.NumeroPlastico,
                            MontoARS = detalleAutorizacion.MontoARS,
                            MontoAsegurado = detalleAutorizacion.MontoAseg,
                            MontoReclamado = detalleAutorizacion.MontoReclamado

                        });


                    }
                }

                if (errorlist.Count == 0)
                {
                    var responseOk = new ConciliarAutorizacionResponseDto { Errores = null };
                    return new ResponseDto<ConciliarAutorizacionResponseDto>(responseOk, StatusCodes.Status200OK, DescripcionRespuesta.OK);

                }

                var responseErrores = new ConciliarAutorizacionResponseDto { Errores = errorlist };
                return new ResponseDto<ConciliarAutorizacionResponseDto>(responseErrores, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);



            }
            catch (Exception e)
            {
                return new ResponseDto<ConciliarAutorizacionResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }


        }
    }
}
