using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Sesion.ReactivarSesion
{
    public class ReactivarSesionCommand : IRequest<ResponseDto<ReactivarSesionResponseDto>>
    {
        public string NumeroAutorizacion { get; set; }
        public int? Anio { get; set; }

        [JsonIgnore]
        public long? CodigoPss { get; set; }
    }
}
