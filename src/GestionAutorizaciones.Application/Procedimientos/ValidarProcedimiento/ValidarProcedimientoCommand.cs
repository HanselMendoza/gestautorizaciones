using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Procedimientos.ValidarProcedimiento
{
    public class ValidarProcedimientoCommand : IRequest<ResponseDto<ValidarProcedimientoResponseDto>>
    {
        public long CodigoProcedimiento { get; set; }
        public long TipoServicio { get; set; }
        public decimal? Monto { get; set; }
        public int? Frecuencia { get; set; }
        public string UsuarioRegistra { get; set; }
        [JsonIgnore]
        public long NumeroSesion { get; set; }
    }
}
