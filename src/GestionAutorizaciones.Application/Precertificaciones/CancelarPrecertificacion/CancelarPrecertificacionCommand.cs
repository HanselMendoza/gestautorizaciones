using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;
using System.Text.Json.Serialization;

namespace GestionAutorizaciones.Application.Precertificaciones.CancelarPrecertificacion
{
    public class CancelarPrecertificacionCommand : IRequest<ResponseDto<CancelarPrecertificacionResponseDto>>
    {
        public int Compania { get; set; }
        public long NumeroPrecertificacion { get; set; }
        [JsonIgnore]
        public string TipoPss { get; set; }
        [JsonIgnore]
        public long CodigoPss { get; set; }
    }
}
