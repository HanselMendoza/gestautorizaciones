using AutoMapper;
using GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidos;
using GestionAutorizaciones.Domain.Entities;

namespace GestionAutorizaciones.Application.Procedimientos.Common
{
    public class ProcedimientoMappingProfile : Profile
    {
        public ProcedimientoMappingProfile()
        {
            CreateMap<Procedimiento, ProcedimientoDTO>().ReverseMap();
            CreateMap<ProcedimientoNoServicio, ProcedimientoDTO>().ReverseMap();
        }
    }
}
