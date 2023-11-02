using AutoMapper;
using GestionAutorizaciones.Application.Prestadores.ObtenerPrestador;

namespace GestionAutorizaciones.Application.Prestadores.Common
{
    public class PrestadorMappingProfile : Profile
    {
        public PrestadorMappingProfile()
        {
            CreateMap<Domain.Entities.Prestador, PrestadorDTO>()
           .ForMember(pts => pts.EsARS, opt => opt.MapFrom(ps => ps.Ars))
           .ForMember(pts => pts.Pyp, opt => opt.MapFrom(ps => ps.Pyp.Equals("S") ? true : false))
           .ReverseMap();
        }
    }
}