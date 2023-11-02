using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Precertificaciones.ConfirmarPrecertificacion
{
    public class ConfirmarPrecertificacionCommand : IRequest<ResponseDto<ConfirmarPrecertificacionResponseDto>>
    {
        public string UsuarioRegistra { get; set; }
        public int Compania { get; set; }
        public long NumeroPrecertificacion { get; set; }
        [JsonIgnore]
        public long NumeroSesion { get; set; }
    }
}
