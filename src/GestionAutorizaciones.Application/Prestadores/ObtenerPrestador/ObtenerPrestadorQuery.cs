using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerPrestador
{
    public class ObtenerPrestadorQuery : IRequest<ResponseDto<ObtenerPrestadorResponseDto>>
    {
        public string TipoPss { get; set; }
        public long CodigoPss { get; set; }


    }
}
