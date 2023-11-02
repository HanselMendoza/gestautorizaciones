using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;
using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace GestionAutorizaciones.Application.Autorizaciones.CompararAutorizacion
{
    public class CompararAutorizacionCommand : IRequest<ResponseDto<CompararAutorizacionResponseDto>>
    {
        public List<Autorizacion> Autorizaciones { get; set; }
        [JsonIgnore]
        public long NumeroSesion { get; set; }
    }

    public class Autorizacion
    {
        public DateTime? Fecha { get; set; }
        public int? Ano { get; set; }
        public int? Compania { get; set; }
        public int? Ramo { get; set; }
        public long? Secuencial { get; set; }
        public int? Estado { get; set; }
        public long? NumeroPlastico { get; set; }
        public decimal? MontoReclamado { get; set; }
        public decimal? MontoARS { get; set; }
        public decimal? MontoAseg { get; set; }
    }
}
