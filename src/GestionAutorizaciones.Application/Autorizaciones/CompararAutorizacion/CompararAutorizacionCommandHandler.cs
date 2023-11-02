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

namespace GestionAutorizaciones.Application.Autorizaciones.CompararAutorizacion
{
    public class CompararAutorizacionCommandHandler : IRequestHandler<CompararAutorizacionCommand, ResponseDto<CompararAutorizacionResponseDto>>
    {
        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IPrestadorRepositorio _prestadorRepositorio;
        public CompararAutorizacionCommandHandler(IPrestadorRepositorio prestadorRepositorio,
             ISesionRepositorio sesionRepositorio)
        {
            _prestadorRepositorio = prestadorRepositorio;
            _sesionRepositorio = sesionRepositorio;
        }

        public async Task<ResponseDto<CompararAutorizacionResponseDto>> Handle(CompararAutorizacionCommand request, CancellationToken cancellationToken)
        {

            try
            {
                if (request.Autorizaciones == null || request.Autorizaciones.Count == 0)
                {
                    return new ResponseDto<CompararAutorizacionResponseDto>(null, StatusCodes.Status204NoContent, DescripcionRespuesta.NoContent);
                }
                DateTime minDate = (DateTime)request.Autorizaciones.Min(a => a.Fecha);
                DateTime maxDate = (DateTime)request.Autorizaciones.Max(a => a.Fecha);

                InfoSesion resultInfoSesionPss = await _sesionRepositorio.ObtenerInfoSesion(request.NumeroSesion);

                if (resultInfoSesionPss == null || resultInfoSesionPss.CodigoPss == null)
                {
                    return new ResponseDto<CompararAutorizacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

                List<ReclamacionPss> resultAutorizaciones = (List<ReclamacionPss>)await _prestadorRepositorio.ObtenerReclamacionesPss(resultInfoSesionPss.TipoPss,
                    long.Parse(resultInfoSesionPss.CodigoPss), minDate, maxDate, null, null, null, null, null);

                if (resultAutorizaciones == null || resultAutorizaciones.Count == 0)
                {
                    return new ResponseDto<CompararAutorizacionResponseDto>(null, StatusCodes.Status204NoContent, DescripcionRespuesta.NoContent);

                }

                List<ErrorCompararAutorizacion> errorlist = new List<ErrorCompararAutorizacion>();

                foreach (Autorizacion detalleAutorizacion in request.Autorizaciones)
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
                            errorlist.Add(new ErrorCompararAutorizacion
                            {
                                Error = new ErrorComparar { Codigo = CodigoErrorConciliacion.PlasticoNoCoincide, Descripcion = MensajeErrorConciliacion.PlasticoNoCoincide },
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
                            errorlist.Add(new ErrorCompararAutorizacion
                            {
                                Error = new ErrorComparar { Codigo = CodigoErrorConciliacion.EstadosNoCoinciden, Descripcion = MensajeErrorConciliacion.EstadosNoCoinciden },
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
                            errorlist.Add(new ErrorCompararAutorizacion
                            {
                                Error = new ErrorComparar { Codigo = CodigoErrorConciliacion.MontosNoCoinciden, Descripcion = MensajeErrorConciliacion.MontosNoCoinciden },
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
                        errorlist.Add(new ErrorCompararAutorizacion
                        {
                            Error = new ErrorComparar { Codigo = CodigoErrorConciliacion.AutorizacionNoExiste, Descripcion = MensajeErrorConciliacion.AutorizacionNoExiste },
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
                    var responseOk = new CompararAutorizacionResponseDto { Errores = null };
                    return new ResponseDto<CompararAutorizacionResponseDto>(responseOk, StatusCodes.Status200OK, DescripcionRespuesta.OK);

                }

                var responseErrores = new CompararAutorizacionResponseDto { Errores = errorlist };
                return new ResponseDto<CompararAutorizacionResponseDto>(responseErrores, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);



            }
            catch (Exception e)
            {
                return new ResponseDto<CompararAutorizacionResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }

        }
    }
}
