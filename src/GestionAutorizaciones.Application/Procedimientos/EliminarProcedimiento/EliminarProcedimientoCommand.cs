using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Procedimientos.EliminarProcedimiento
{
    public class EliminarProcedimientoCommand : IRequest<ResponseDto<EliminarProcedimientoResponseDto>>
    {

        public long? Procedimiento { get; set; }
        [JsonIgnore]
        public long NumeroSesion { get; set; }
    }
}
