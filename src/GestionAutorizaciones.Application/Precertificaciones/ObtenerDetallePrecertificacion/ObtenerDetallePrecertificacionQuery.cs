using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Precertificaciones.ObtenerDetallePrecertificacion
{
    public class ObtenerDetallePrecertificacionQuery : IRequest<ResponseDto<ObtenerDetallePrecertificacionResponseDto>>
    {
        public int Compania { get; set; }
        public long NumeroPrecertificacion { get; set; }
        [JsonIgnore]
        public long NumeroSesion { get; set; }

    }
}
