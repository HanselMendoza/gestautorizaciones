using System;

namespace GestionAutorizaciones.Application.Auth.Common
{
    public class Usuario
    {
        public string Username { get; set; }

        public string Email { get; set; }

        public bool? IsActive { get; set; }

        public bool? IsExternal { get; set; }

        public bool? IsSuperUser { get; set; }

        public PerfilUsuario Profile { get; set; }

        public bool? Blocked { get; set; }

        public MetadataConfig Config { get; set; }
    }

    public class MetadataConfig
    {
        public string Id { get; set; }
        public string Role { get; set; }
    }

    public class PerfilUsuario
    {
        public string Name { get; set; }
        public string LastName { get; set; }
        public string DocumentType { get; set; }
        public string DocumentNumber { get; set; }
        public string Sex { get; set; }
        public DateTime? Birthdate { get; set; }
    }
}
