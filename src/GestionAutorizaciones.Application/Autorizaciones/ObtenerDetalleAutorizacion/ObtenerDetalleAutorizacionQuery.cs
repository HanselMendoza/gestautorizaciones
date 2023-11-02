using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Autorizaciones.ObtenerDetalleAutorizacion
{
    public class ObtenerDetalleAutorizacionQuery : IRequest<ResponseDto<ObtenerDetalleAutorizacionResponseDto>>
    {
        public string NumeroAutorizacion { get; set; }
        public int? Ano { get; set; }
        public string TipoPss { get; set; }
        public int? CodigoPss { get; set; }
    }
}
