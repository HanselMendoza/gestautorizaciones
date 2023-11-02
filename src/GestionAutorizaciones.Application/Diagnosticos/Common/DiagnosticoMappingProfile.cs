using AutoMapper;
using GestionAutorizaciones.Application.Diagnosticos.ObtenerDiagnosticos;

namespace GestionAutorizaciones.Application.Diagnosticos.Common
{
	public class DiagnosticoMappingProfile : Profile
	{
		public DiagnosticoMappingProfile()
		{
			CreateMap<Domain.Entities.Diagnostico, ObtenerDiagnosticosDto>()
				.ReverseMap();

		}
	}
}
