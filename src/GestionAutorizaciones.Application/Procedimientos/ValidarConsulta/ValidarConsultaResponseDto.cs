using System;

namespace GestionAutorizaciones.Application.Procedimientos.ValidarConsulta
{
    public class ValidarConsultaResponseDto
    {
        public long? Codigo { get; set; }
        public long? Frecuencia { get; set; }
        public decimal? MontoReclamado { get; set; }
        public decimal? MontoArs { get; set; }
        public decimal? MontoAfiliado { get; set; }

    }
}
