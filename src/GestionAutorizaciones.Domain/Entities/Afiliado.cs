using System;

namespace GestionAutorizaciones.Domain.Entities
{
    public class Afiliado
    {
        public long? NumeroAsegurado { get; set; }
        public string Nombres { get; set; }
        public string PrimerApellido { get; set; }
        public string SegundoApellido { get; set; }
        public string Sexo { get; set; }
        public DateTime? FechaNacimiento { get; set; }
        public string Nacionalidad { get; set; }
        public string Parentesco { get; set; }
        public long? CodigoEmpresa { get; set; }
        public string Empresa { get; set; }
        public string TelefonoEmpresa { get; set; }
        public string DireccionEmpresa { get; set; }
        public string Actividad { get; set; }
        public string TipoDocumento { get; set; }
        public DateTime? FechaSolicitud { get; set; }
        public string Cedula { get; set; }
        public string DescripcionPlan { get; set; }
        public string TipoPlan { get; set; }
        public string Nss { get; set; }
    }
}
