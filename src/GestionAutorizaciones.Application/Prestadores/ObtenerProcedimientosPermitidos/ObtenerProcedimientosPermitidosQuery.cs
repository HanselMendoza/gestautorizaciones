using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidos
{
    public class ObtenerProcedimientosPermitidosQuery : ParametrosPaginacionDto, IRequest<PaginacionDto<ObtenerProcedimientosPermitidosResponseDto>>
    {
        public string TipoPss { get; set; }
        public long CodigoPss { get; set; }
        public long? Cobertura { get; set; }
        public string NombreCobertura { get; set; }
        public long? Servicio { get; set; }
    }
}
