using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado
{
    public class ObtenerAseguradoQuery : IRequest<ResponseDto<ObtenerAseguradoResponseDto>>
    {
        public long NumeroPlastico { get; set; }
        [JsonIgnore]
        public long NumeroSesion { get; set; }

        public string TipoPss { get; set; }
        public int CodigoPss { get; set; }
    }
}
