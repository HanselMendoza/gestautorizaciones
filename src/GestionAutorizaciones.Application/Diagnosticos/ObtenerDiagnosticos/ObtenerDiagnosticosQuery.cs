using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Diagnosticos.ObtenerDiagnosticos
{
	public record ObtenerDiagnosticosQuery(string Buscar, int Pagina, int Tamanio) : IRequest<PaginacionDto<ObtenerDiagnosticosResponseDto>>;
}
