using System.Collections.Generic;

namespace GestionAutorizaciones.Application.Diagnosticos.ObtenerDiagnosticos
{
	public record ObtenerDiagnosticosResponseDto(string Busqueda, ICollection<ObtenerDiagnosticosDto> Diagnoticos);
	public record ObtenerDiagnosticosDto(string Codigo, string Descripcion);
}
