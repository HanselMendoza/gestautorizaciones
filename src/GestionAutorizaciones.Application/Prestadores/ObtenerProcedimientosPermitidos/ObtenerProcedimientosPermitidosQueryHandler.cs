using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using GestionAutorizaciones.Domain.Entities;
using System.Linq;
using GestionAutorizaciones.Application.Common.Paginacion;
using AutoMapper;
using GestionAutorizaciones.Application.Procedimientos.Common;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidos
{

    public class ObtenerProcedimientosPermitidosQueryHandler : IRequestHandler<ObtenerProcedimientosPermitidosQuery, PaginacionDto<ObtenerProcedimientosPermitidosResponseDto>>
    {
        private readonly IProcedimientoRepositorio _procedimientoRepositorio;
        private readonly IMapper _mapper;

        public ObtenerProcedimientosPermitidosQueryHandler(IMapper mapper, IProcedimientoRepositorio procedimientoRepositorio)
        {
            _mapper = mapper;
            _procedimientoRepositorio = procedimientoRepositorio;
        }

        public async Task<PaginacionDto<ObtenerProcedimientosPermitidosResponseDto>> Handle(ObtenerProcedimientosPermitidosQuery request, CancellationToken cancellationToken)
        {
            try
            {
                var result = await _procedimientoRepositorio.ObtenerProcedimientos(request.TipoPss, request.CodigoPss, request.Servicio);
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

                List<ProcedimientoDTO> procedimientos = _mapper.Map<List<Procedimiento>, List<ProcedimientoDTO>>(result.ToList());

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
