using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Procedimientos.ValidarConsulta
{
    public class ValidarConsultaCommand : IRequest<ResponseDto<ValidarConsultaResponseDto>>
    {
        public string UsuarioRegistra { get; set; }

        [JsonIgnore]
        public long NumeroSesion { get; set; }
    }
}
