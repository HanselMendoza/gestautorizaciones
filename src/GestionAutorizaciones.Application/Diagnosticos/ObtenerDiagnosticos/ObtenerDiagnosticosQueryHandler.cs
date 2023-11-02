using AutoMapper;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Diagnosticos.Common;
using MediatR;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace GestionAutorizaciones.Application.Diagnosticos.ObtenerDiagnosticos
{
	public class ObtenerDiagnosticosQueryHandler : IRequestHandler<ObtenerDiagnosticosQuery, PaginacionDto<ObtenerDiagnosticosResponseDto>>
	{
		private readonly IDiagnosticoRepository _diagnosticoRepository;
		private readonly IMapper _mapper;

		public ObtenerDiagnosticosQueryHandler(IDiagnosticoRepository diagnosticoRepository, IMapper mapper)
		{
			_diagnosticoRepository = diagnosticoRepository;
			_mapper = mapper;
		}

		public async Task<PaginacionDto<ObtenerDiagnosticosResponseDto>> Handle(ObtenerDiagnosticosQuery request, CancellationToken cancellationToken)
		{
			var (diagnosticos, totalPaginas, totalRegistros) = await _diagnosticoRepository
				.ObtenerDiagnosticos(request.Buscar, request.Pagina, request.Tamanio);

			var diagnosticosDto = _mapper.Map<ICollection<ObtenerDiagnosticosDto>>(diagnosticos);

			var result = new ObtenerDiagnosticosResponseDto(request.Buscar, diagnosticosDto);

			var tamanioPagina = request.Tamanio > result.Diagnoticos.Count ? result.Diagnoticos.Count : request.Tamanio;

			return PaginacionDto<ObtenerDiagnosticosResponseDto>.OK(result, request.Pagina, tamanioPagina, totalPaginas, totalRegistros);
		}
	}
}
