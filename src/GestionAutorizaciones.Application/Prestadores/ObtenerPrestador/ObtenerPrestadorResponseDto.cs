using System;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerPrestador
{
    public class ObtenerPrestadorResponseDto
    {
        public PrestadorDTO Prestador { get; set; }
    }

    public class PrestadorDTO
    {
        public string TipoPss { get; set; }
        public string Tipo { get; set; }
        public long? Codigo { get; set; }
        public string Nombre { get; set; }
        public string Cedula { get; set; }
        public string Rnc { get; set; }
        public long? CodigoEstado { get; set; }
        public string DescripcionEstado { get; set; }
        public string Activo { get; set; }
        public DateTime? FechaIngreso { get; set; }
        public DateTime? FechaSalida { get; set; }
        public string EsARS { get; set; }
        public bool Pyp { get; set; }
    }
}