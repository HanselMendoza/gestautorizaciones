using System;
using System.Collections.Generic;

namespace GestionAutorizaciones.Application.Auth.Common
{
    public class ClienteConfig
    {
        public string ClientId { get; set; }
        public string ApiKey { get; set; }

        public string NombreCliente { get; set; }
        public ICollection<string> Permisos { get; set; }
        public bool? RequiereTerminal { get; set; }
        public bool? PuedePreAutorizar { get; set; }
        public int? EstadoPreAutorizado { get; set; }
        public int? EstadoAperturado { get; set; }
        public string UsuarioIngresoReclamacion { get; set; }
    }
}