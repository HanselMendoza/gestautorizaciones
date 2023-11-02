using GestionAutorizaciones.Application.Common.Dtos;
using System;

namespace GestionAutorizaciones.Application.Autorizaciones.ObtenerAutorizaciones
{
    public class ObtenerAutorizacionesRequest : ParametrosPaginacionDto
    {
        public int? Ramo { get; set; }
        public long? Secuencial { get; set; }
        public string UsuarioIngreso { get; set; }
        public long? NumeroPlastico { get; set; }
        public DateTime FechaInicio { get; set; }
        public DateTime FechaFin { get; set; }
        public int? Compania { get; set; }

    }
}