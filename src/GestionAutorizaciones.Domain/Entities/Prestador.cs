using System;

namespace GestionAutorizaciones.Domain.Entities
{
    public class Prestador
    {
        public string TipoPss { get; set; }
        public string Tipo { get; set; }
        public long? Codigo { get; set; }
        public string Nombre { get; set; }
        public string Cedula { get; set; }
        public string Rnc { get; set; }
        public string CodigoEstado { get; set; }
        public string DescripcionEstado { get; set; }
        public string Activo { get; set; }
        public DateTime? FechaIngreso { get; set; }
        public DateTime? FechaSalida { get; set; }
        public string Ars { get; set; }
        public string Pyp { get; set; }
    }
}