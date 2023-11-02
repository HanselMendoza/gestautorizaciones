
namespace GestionAutorizaciones.Domain.Entities
{
    public class Procedimiento
    {
        public long? Codigo { get; set; }
        public string Nombre { get; set; }
        public string Tipo { get; set; }
        public string Servicio { get; set; }
        public string TipoServicio { get; set; }
        public long? Cobertura { get; set; }
        public string NombreCobertura { get; set; }
    }
}
