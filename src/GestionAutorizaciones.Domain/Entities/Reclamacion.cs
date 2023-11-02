using System;

namespace GestionAutorizaciones.Domain.Entities
{

    public class Reclamacion
    {
        public int Ano { get; set; }
        public int Compania { get; set; }
        public int Ramo { get; set; }
        public long Secuencial { get; set; }
        public string UsuarioIngreso { get; set; }
        public DateTime? FechaApertura { get; set; }
        public long? Estatus { get; set; }
        public string Descripcion { get; set; }
        public long NumeroPlastico { get; set; }
        public long? Cobertura { get; set; }
        public string DescripcionCobertura { get; set; }
        public long? Frecuencia { get; set; }
        public decimal? MontoReclamado { get; set; }
        public decimal? MontoPagado { get; set; }
        public decimal? MontoAsegurado { get; set; }
        public string TipoReclamante { get; set; }
        public long? Reclamante { get; set; }
        public string Nombre { get; set; }
        public long? TipoServicio { get; set; }
        public string ValidarReclamacion { get; set; }
        public string DescripcionReclamacion { get; set; }
    }
}
