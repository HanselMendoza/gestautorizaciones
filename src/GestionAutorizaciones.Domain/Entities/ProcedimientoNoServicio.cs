namespace GestionAutorizaciones.Domain.Entities
{
    public class ProcedimientoNoServicio
    {
        public long? Codigo { get; set; }
        public string Nombre { get; set; }
        public string Tipo { get; set; }
        public string Servicio { get; set; }
        public long? Cobertura { get; set; }
        public string NombreCobertura { get; set; }
    }
}
