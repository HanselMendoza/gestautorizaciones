using AutoMapper;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Common.Paginacion;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Domain.Entities;
using MediatR;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;

namespace GestionAutorizaciones.Application.Autorizaciones.ObtenerAutorizaciones
{
    public class ObtenerAutorizacionesQueryHandler : IRequestHandler<ObtenerAutorizacionesQuery, PaginacionDto<ObtenerAutorizacionesResponseDto>>
    {
        private readonly IPrestadorRepositorio _prestadorRepositorio;
        private readonly IMapper _mapper;
        

        public ObtenerAutorizacionesQueryHandler(IMapper mapper, IPrestadorRepositorio prestadorRepositorio)
        {
            _mapper = mapper;
            _prestadorRepositorio = prestadorRepositorio;
        }

        public async Task<PaginacionDto<ObtenerAutorizacionesResponseDto>> Handle(ObtenerAutorizacionesQuery request, CancellationToken cancellationToken)
        {
            const int estatusSuspendido = 361;
            try
            {
                List<ReclamacionPss> result = (List<ReclamacionPss>)await _prestadorRepositorio.ObtenerReclamacionesPss(request.TipoPss, request.CodigoPss,
                    request.FechaInicio, request.FechaFin, request.Ramo, request.Secuencial, request.UsuarioIngreso, request.NumeroPlastico, request.Compania);

                if (result == null || result.Count == 0)
                {
                    return new PaginacionDto<ObtenerAutorizacionesResponseDto>(null, request.Pagina, request.TamanoPagina, 0, 0, DescripcionRespuesta.NoContent,
                        StatusCodes.Status204NoContent);
                }

                List<AutorizacionDTO> autorizaciones = _mapper.Map<List<ReclamacionPss>, List<AutorizacionDTO>>(result);

                var asQueryable = autorizaciones.Where(e => e.Estatus != estatusSuspendido).AsQueryable();
                var dataPaginada = asQueryable.Paginar(request.Pagina, request.TamanoPagina).ToList();
                var totalElementos = autorizaciones.Count;
                var totalPaginas = (int)Math.Ceiling(totalElementos / (decimal)request.TamanoPagina);

                ObtenerAutorizacionesResponseDto respuestaPaginada = new ObtenerAutorizacionesResponseDto
                {
                    Autorizaciones = dataPaginada
                };

                return new PaginacionDto<ObtenerAutorizacionesResponseDto>(respuestaPaginada, request.Pagina, request.TamanoPagina, totalPaginas, totalElementos,
                    DescripcionRespuesta.OK, CodigoRespuesta.OK);

            }
            catch (Exception e)
            {
                return new PaginacionDto<ObtenerAutorizacionesResponseDto>(null, request.Pagina, request.TamanoPagina, 0, 0,
                    e.StackTrace, StatusCodes.Status500InternalServerError);
            }


        }
    }
}