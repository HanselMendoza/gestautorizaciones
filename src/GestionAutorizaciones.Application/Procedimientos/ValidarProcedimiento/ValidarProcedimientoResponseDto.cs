using System;

namespace GestionAutorizaciones.Application.Procedimientos.ValidarProcedimiento
{
    public class ValidarProcedimientoResponseDto
    {
        public long? Codigo { get; set; }
        public long? Frecuencia { get; set; }
        public decimal? MontoReclamado { get; set; }
        public decimal? MontoArs { get; set; }
        public decimal? MontoAfiliado { get; set; }

    }
}
