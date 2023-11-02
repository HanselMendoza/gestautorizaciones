
using System;

namespace GestionAutorizaciones.Domain.Entities
{
    public class Precertificacion
    {
        public int? Prefijo { get; set; }
        public long? Secuencial { get; set; }
        public int? Compania { get; set; }
        public int? Ramo { get; set; }
        public long? SecuenciaPoliza { get; set; }
        public long? Plan { get; set; }
        public string DescripcionPlan { get; set; }
        public string TipoReclamante { get; set; }
        public long? CodigoPss { get; set; }
        public string NombrePss { get; set; }
        public string TipoHos { get; set; }
        public long? PerHos { get; set; }
        public long? DepUso { get; set; }
        public long? NumeroPlastico { get; set; }
        public string NumeroAsegurado { get; set; }
        public string NumeroCedula { get; set; }
        public DateTime? FechaIngreso { get; set; }
        public DateTime? FechaTransaccion { get; set; }
        public string UsuarioIngreso { get; set; }
        public long? Estatus { get; set; }
        public string DescripcionEstatus { get; set; }
        public long? Servicio { get; set; }
        public long? TipoCobertura { get; set; }
        public int? Cobertura { get; set; }
        public string DescripcionCobertura{ get; set; }
        public decimal? MontoLimite { get; set; }
        public decimal? MontoReclamado { get; set; }
        public long? Frecuencia { get; set; }
        public decimal? MontoReserva { get; set; }
        public decimal? MontoPagado { get; set; }
        public decimal? MontoPagadoAfiliado { get; set; }


    }
}

