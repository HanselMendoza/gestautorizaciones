namespace GestionAutorizaciones.Domain.Entities
{
    public class LimiteCobertura
    {
        public int Codigo { get; set; }
        public string Descripcion { get; set; }
        public double Limite { get; set; }
        public int Compania { get; set; }
    }
}
