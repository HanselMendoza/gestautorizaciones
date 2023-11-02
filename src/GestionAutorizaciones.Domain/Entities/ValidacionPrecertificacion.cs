
namespace GestionAutorizaciones.Domain.Entities
{
    public class ValidacionPrecertificacion
    {
        public long? NumeroPrecertificacion { get; set; }
        public string TipoAutorizacion { get; set; }
        public string NumeroAutorizacion { get; set; }
        public int? CodigoValidacion { get; set; }
    }
}

