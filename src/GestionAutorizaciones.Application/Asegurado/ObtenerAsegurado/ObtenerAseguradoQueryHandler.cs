using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using MediatR;
using AutoMapper;
using GestionAutorizaciones.Application.Common.Dtos;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using static GestionAutorizaciones.Application.Common.Utils.Funciones;
using Microsoft.AspNetCore.Http;
using System;
using GestionAutorizaciones.Domain.Entities;
using GestionAutorizaciones.Domain.Entities.Response;
using System.Linq;
using GestionAutorizaciones.Application.Asegurado.Common;
using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Prestadores.Common;

namespace GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado
{
    public class ObtenerAseguradoQueryHandler : IRequestHandler<ObtenerAseguradoQuery, ResponseDto<ObtenerAseguradoResponseDto>>
    {
        private readonly IMapper _mapper;
        private readonly IAseguradoRepositorio _aseguradoRepositorio;
        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IPrestadorRepositorio _prestadorRepositorio;

        public ObtenerAseguradoQueryHandler(IMapper mapper, IAseguradoRepositorio aseguradoRepositorio,
            ISesionRepositorio sesionRepositorio,
            IPrestadorRepositorio prestadorRepositorio)
        {
            _mapper = mapper;
            _aseguradoRepositorio = aseguradoRepositorio;
            _sesionRepositorio = sesionRepositorio;
            _prestadorRepositorio = prestadorRepositorio;
        }
        public async Task<ResponseDto<ObtenerAseguradoResponseDto>> Handle(ObtenerAseguradoQuery request, CancellationToken cancellationToken)
        {
            try
            {
                var resultValidarAfiliado = await _sesionRepositorio.Infoxproc(NombreOperacion.ValidarAsegurado, request.NumeroSesion, Convert.ToString(request.NumeroPlastico), null, null, null);

                if (resultValidarAfiliado == null)
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, StatusCodes.Status204NoContent, DescripcionRespuesta.NoContent);
                }


                if (resultValidarAfiliado.Outnum1 == RespuestaInfoxprocAfiliado.PlasticoNoExiste)
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, int.Parse(RespuestaInfoxprocAfiliado.PlasticoNoExiste),
                        MensajeInfoxproc.PlasticoNoExiste);
                }
                
                if (resultValidarAfiliado.Outnum1 == RespuestaInfoxprocAfiliado.NoServicio)
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, int.Parse(RespuestaInfoxprocAfiliado.NoServicio),
                        MensajeInfoxproc.PlanNoVigente);
                }

                if (resultValidarAfiliado.Outnum1 == RespuestaInfoxprocAfiliado.PlasticoInvalidado)
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, int.Parse(RespuestaInfoxprocAfiliado.PlasticoInvalidado),
                        MensajeInfoxproc.PlasticoInvalidado);
                }

                if (resultValidarAfiliado.Outnum1 != RespuestaInfoxprocAfiliado.AseguradoValido)
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, int.Parse(RespuestaInfoxprocAfiliado.CondicionEspecial),
                        MensajeInfoxproc.CondicionEspecial);
                }

                var resultOrigen = await _aseguradoRepositorio.ObtenerOrigenPlastico(request.NumeroPlastico);
                if (resultOrigen == null)
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, int.Parse(RespuestaInfoxprocAfiliado.PlasticoNoExiste),
                        MensajeInfoxproc.PlasticoNoExiste);
                }

                var origenPlastico = ObtenerOrigenPorParametro(resultOrigen.Codigo);

                if (origenPlastico.Codigo == Decimal.Zero)
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, int.Parse(RespuestaInfoxprocAfiliado.PlasticoNoExiste),
                        MensajeInfoxproc.PlasticoNoExiste);
                }

                var resultAfiliado = await _aseguradoRepositorio.ObtenerAfiliado(tipoId: TipoDocumento.Plastico,
                    identificacion: Convert.ToString(request.NumeroPlastico), compania: origenPlastico.Compania);

                if (resultAfiliado == null)
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, StatusCodes.Status204NoContent,
                        DescripcionRespuesta.NoContent);
                }

                var afiliado = _mapper.Map<AfiliadoDTO>(resultAfiliado);
                afiliado.NumeroPlastico = request.NumeroPlastico;

                var resultObtenerInfoSesion = await _sesionRepositorio.ObtenerInfoSesion(request.NumeroSesion);
                if (resultObtenerInfoSesion == null)
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, StatusCodes.Status400BadRequest, "No se pudo obtener la sesión indicada");
                }

                if (string.IsNullOrWhiteSpace(resultObtenerInfoSesion?.CodigoAsegurado) || string.IsNullOrWhiteSpace(resultObtenerInfoSesion?.SecuenciaDependiente))
                {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, StatusCodes.Status400BadRequest, "La sesión no posee código asegurado / secuencia dependiente"); 
                }

                var resultValidaPrestador = await _prestadorRepositorio.ValidarPrestadorOfreceServicio(request.TipoPss, request.CodigoPss, Convert.ToInt32(resultObtenerInfoSesion.CodigoAsegurado), Convert.ToInt32(resultObtenerInfoSesion.SecuenciaDependiente));
                
                if (!resultValidaPrestador.Aplica.Value) {
                    return new ResponseDto<ObtenerAseguradoResponseDto>(null, Convert.ToInt32(RespuestaInfoxprocAfiliado.NoServicio) ,
                        MensajeInfoxproc.PrestadorNoPuedeOfrecerServicio);
                }

                try
                {
                    var nucleo = (List<Nucleo>)await _aseguradoRepositorio.ObtenerNucleos(request.NumeroPlastico);

                    if (nucleo != null)
                    {
                        var acompanantes = _mapper.Map<List<Nucleo>, List<Acompanante>>(nucleo);
                        afiliado.Acompanantes = acompanantes;
                    }
                }
                catch (Exception) {}

                try
                {
                    var telefono = await _aseguradoRepositorio.ObtenerTelefono(request.NumeroPlastico);
                    afiliado.Telefono = telefono?.NumeroTelefono;
                }
                catch (Exception) {}

                var data = new ObtenerAseguradoResponseDto
                {
                    Compania = new Compania { Codigo = origenPlastico.Compania, Nombre = origenPlastico.Descripcion },
                    Afiliado = afiliado

                };
                return new ResponseDto<ObtenerAseguradoResponseDto>(data, StatusCodes.Status200OK, DescripcionRespuesta.OK);
            }
            catch (Exception e)
            {
                return new ResponseDto<ObtenerAseguradoResponseDto>(null, StatusCodes.Status500InternalServerError, e.StackTrace);
            }

        }
    }
}