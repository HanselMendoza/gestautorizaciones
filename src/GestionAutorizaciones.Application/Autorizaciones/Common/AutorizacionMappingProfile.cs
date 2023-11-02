using AutoMapper;
using GestionAutorizaciones.Application.Autorizaciones.ObtenerAutorizaciones;
using GestionAutorizaciones.Application.Autorizaciones.ProcesarAutorizacion;
using GestionAutorizaciones.Domain.Entities;

namespace GestionAutorizaciones.Application.Autorizaciones.Common
{
    public class AutorizacionMappingProfile : Profile
    {
        public AutorizacionMappingProfile()
        {
            CreateMap<ReclamacionPss, AutorizacionDTO>()
                .ReverseMap();
            CreateMap<MedicamentoDto, MedicamentoResultDto>().ReverseMap();
        }
    }
}
