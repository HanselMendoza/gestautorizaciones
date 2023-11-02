using AutoMapper;
using GestionAutorizaciones.Domain.Entities;
using GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado;

namespace GestionAutorizaciones.Application.Asegurado.Common
{
    public class AseguradoMappingProfile : Profile
    {
        public AseguradoMappingProfile()
        {
            CreateMap<Afiliado, AfiliadoDTO>()
                .ForMember(pts => pts.NumeroAsegurado, opt => opt.MapFrom(ps => ps.NumeroAsegurado))
                .ForMember(pts => pts.Sexo, opt => opt.MapFrom(ps => ps.Sexo))
                .ForMember(pts => pts.Plan, opt => opt.MapFrom(ps => ps.DescripcionPlan))
                .ForMember(pts => pts.Apellidos, opt => opt.MapFrom(ps => ps.PrimerApellido + ' ' + ps.SegundoApellido))
                .ReverseMap();

            CreateMap<Nucleo, Acompanante>()
                .ForMember(pts => pts.Sexo, opt => opt.MapFrom(ps => ps.Sexo))
                .ReverseMap();
        }
    }
}
