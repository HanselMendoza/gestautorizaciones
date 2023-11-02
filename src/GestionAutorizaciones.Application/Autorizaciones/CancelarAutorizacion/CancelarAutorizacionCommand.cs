using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Domain.Entities.Enums;
using MediatR;

namespace GestionAutorizaciones.Application.Autorizaciones.CancelarAutorizacion
{
    public class CancelarAutorizacionCommand : IRequest<ResponseDto<CancelarAutorizacionResponseDto>>
    {
        public string UsuarioIngresa { get; set; }

        [JsonIgnore]
        public string NumeroAutorizacion { get; set; }
        [JsonIgnore]
        public long NumeroSesion { get; set; }

        public long NumeroPlastico { get; set; }
        public MotivoCancelacionAutorizacion CodigoMotivo { get; set; } = MotivoCancelacionAutorizacion.NoEspecifico;
    }
}
