namespace GestionAutorizaciones.Domain.Entities
{
    public class DetalleReclamacion
    {
        public int? Ano { get; set; }
        public int? Compania { get; set; }
        public int? Ramo { get; set; }
        public long? Secuencial { get; set; }
        public long? Secuencia { get; set; }
        public string Procedimiento { get; set; }
        public decimal? MontoArs { get; set; }
        public decimal? MontoAfiliado { get; set; }
        public decimal? MontoReclamado { get; set; }
        public int? Frecuencia { get; set; }
    }
}

