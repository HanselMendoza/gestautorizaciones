
namespace GestionAutorizaciones.Domain.Entities
{
    public class ActivacionPrecertificacion
    {
        public string NumeroAutorizacion { get; set; }
        public string TipoAutorizacion { get; set; }
        public int? CodigoValidacion { get; set; }
    }
}