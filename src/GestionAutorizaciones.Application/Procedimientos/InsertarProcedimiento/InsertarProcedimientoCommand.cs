using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Procedimientos.InsertarProcedimiento
{
    public class InsertarProcedimientoCommand : IRequest<ResponseDto<InsertarProcedimientoResponseDto>>
    {

        public int? Frecuencia { get; set; }
        public string UsuarioRegistra { get; set; }
        [JsonIgnore]
        public long NumeroSesion { get; set; }
    }
}
