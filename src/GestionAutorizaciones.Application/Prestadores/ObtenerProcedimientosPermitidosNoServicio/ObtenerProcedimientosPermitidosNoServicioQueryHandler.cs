using AutoMapper;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidos;
using GestionAutorizaciones.Application.Procedimientos.Common;
using GestionAutorizaciones.Domain.Entities;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using System.Threading.Tasks;
using System.Threading;
using MediatR;
using GestionAutorizaciones.Application.Common.Paginacion;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidosNoServicio
{
    public class ObtenerProcedimientosPermitidosNoServicioQueryHandler : IRequestHandler<ObtenerProcedimientosPermitidosNoServicioQuery, PaginacionDto<ObtenerProcedimientosPermitidosResponseDto>>
    {
        private readonly IProcedimientoRepositorio _procedimientoRepositorio;
        private readonly IMapper _mapper;

        public ObtenerProcedimientosPermitidosNoServicioQueryHandler(IMapper mapper, IProcedimientoRepositorio procedimientoRepositorio)
        {
            _mapper = mapper;
            _procedimientoRepositorio = procedimientoRepositorio;
        }

        public async Task<PaginacionDto<ObtenerProcedimientosPermitidosResponseDto>> Handle(ObtenerProcedimientosPermitidosNoServicioQuery request, CancellationToken cancellationToken)
        {
            try
            {
                var result = await _procedimientoRepositorio.ObtenerProcedimientosNoServicio(request.TipoPss, request.CodigoPss, request.Servicio);
                var haEncontradoRegistros = result?.Any() ?? false;

                if (!haEncontradoRegistros)
                {
                    return new PaginacionDto<ObtenerProcedimientosPermitidosResponseDto>(null, request.Pagina, request.TamanoPagina,
                        0, 0, DescripcionRespuesta.NoContent, StatusCodes.Status204NoContent);
                }

                if (request.Cobertura.HasValue)
                {
                    result = result.Where(x => x.Cobertura == request.Cobertura);
                }

                if (!string.IsNullOrWhiteSpace(request.NombreCobertura))
                {
                    result = result.Where(x => x.NombreCobertura.ToUpper().StartsWith(request.NombreCobertura.ToUpper()));
                }

                List<ProcedimientoDTO> procedimientos = _mapper.Map<List<ProcedimientoNoServicio>, List<ProcedimientoDTO>>(result.ToList());

                var asQueryable = procedimientos.AsQueryable().OrderBy(x => x.Cobertura);
                var dataPaginada = asQueryable.Paginar(request.Pagina, request.TamanoPagina).ToList();
                var totalElementos = result.Count();
                var totalPaginas = (int)Math.Ceiling(totalElementos / (decimal)request.TamanoPagina);

                ObtenerProcedimientosPermitidosResponseDto respuestaPaginada = new ObtenerProcedimientosPermitidosResponseDto
                {
                    Procedimientos = dataPaginada
                };

                return new PaginacionDto<ObtenerProcedimientosPermitidosResponseDto>(respuestaPaginada, request.Pagina, request.TamanoPagina,
                    totalPaginas, totalElementos, DescripcionRespuesta.OK, StatusCodes.Status200OK);

            }
            catch (Exception e)
            {
                return new PaginacionDto<ObtenerProcedimientosPermitidosResponseDto>(null, request.Pagina, request.TamanoPagina,
                    0, 0, e.StackTrace, StatusCodes.Status500InternalServerError);
            }
        }
    }
}
