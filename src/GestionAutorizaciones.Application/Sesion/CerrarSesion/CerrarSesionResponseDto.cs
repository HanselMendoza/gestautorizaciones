namespace GestionAutorizaciones.Application.Sesion.CerrarSesion
{
    public class CerrarSesionResponseDto
    {
        public CompaniaDetalle Compania { get; set; }
        public AutorizacionDetalle Autorizacion { get; set; }

        public class CompaniaDetalle
        {
            public int? Codigo { get; set; }
            public string Nombre { get; set; }
        }

        public class AutorizacionDetalle
        {
            public string NumeroAutorizacion { get; set; }
            public int? Ramo { get; set; }
            public long? Secuencial { get; set; }
            public string Estado { get; set; }
            public decimal? MontoReclamado { get; set; }
            public decimal? MontoARS { get; set; }
            public decimal? MontoAfiliado { get; set; }

        }

    }
}
