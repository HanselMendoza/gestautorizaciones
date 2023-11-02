using System;
using System.Collections.Generic;

namespace GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado
{
    public class ObtenerAseguradoResponseDto
    {
        public Compania Compania { get; set; }
        public AfiliadoDTO Afiliado { get; set; }

    }
    public class Acompanante
    {
        public string Cedula { get; set; }
        public string Nombres { get; set; }
        public string Apellidos { get; set; }
        public string Sexo { get; set; }
        public string Poliza { get; set; }
    }

    public class AfiliadoDTO
    {
        public long? NumeroAsegurado { get; set; }
        public long? NumeroPlastico { get; set; }
        public string Nombres { get; set; }
        public string Apellidos { get; set; }
        public DateTime? FechaNacimiento { get; set; }
        public string Sexo { get; set; }
        public string Cedula { get; set; }
        public string Nss { get; set; }
        public string Plan { get; set; }
        public bool? SoloPbs { get; set; }
        public bool? Vigente { get; set; }
        public string Telefono { get; set; }
        public string Email { get; set; }
        public List<Acompanante> Acompanantes { get; set; }
        public List<Plan> Planes { get; set; } = new List<Plan>();
    }

    public class Plan
    {
        public long? Codigo { get; set; }
        public string Descripcion { get; set; }
        public string Estado { get; set; }
        public int? Compania { get; set; }
    }

    public class Compania
    {
        public int Codigo { get; set; }
        public string Nombre { get; set; }
    }

}
