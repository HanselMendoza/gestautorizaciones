using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Sesion.CerrarSesion
{
    public class CerrarSesionCommand : IRequest<ResponseDto<CerrarSesionResponseDto>>
    {
        public bool PreAutorizar { get; set; }
        public bool EsARL { get; set; }
        [JsonIgnore]
        public long NumeroSesion { get; set; }

    }
}
