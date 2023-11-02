using System.Collections.Generic;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidos
{
    public class ObtenerProcedimientosPermitidosResponseDto
    {
        public List<ProcedimientoDTO> Procedimientos { get; set; }
    }

    public class ProcedimientoDTO
    {
        public long? Codigo { get; set; }
        public string Nombre { get; set; }
        public string Tipo { get; set; }
        public string Servicio { get; set; }
        public string TipoServicio { get; set; }
        public long? Cobertura { get; set; }
        public string NombreCobertura { get; set; }
        public long? Especialidad { get; set; }
    }
}
