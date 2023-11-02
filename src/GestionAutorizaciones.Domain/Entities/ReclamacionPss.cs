using System;

namespace GestionAutorizaciones.Domain.Entities
{

    public class ReclamacionPss
    {
        public int? Ano { get; set; }
        public int? Compania { get; set; }
        public int? Ramo { get; set; }
        public long? Secuencial { get; set; }
        public string UsuarioIngreso { get; set; }
        public int? TipoServicio { get; set; }
        public DateTime? FechaApertura { get; set; }
        public int? Estatus { get; set; }
        public string DescripcionEstatus { get; set; }
        public long? NumeroPlastico { get; set; }
        public decimal? MontoReclamado { get; set; }
        public decimal? MontoPagado { get; set; }
        public decimal? MontoAsegurado { get; set; }
    }
}
