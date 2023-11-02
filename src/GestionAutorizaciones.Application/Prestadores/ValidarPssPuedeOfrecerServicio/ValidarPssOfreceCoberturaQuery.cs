using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Prestadores.ValidarPssPuedeOfrecerServicio
{
    public class ValidarPssOfreceCoberturaQuery : IRequest<ResponseDto<ValidarPssOfreceCoberturaResponseDto>>
    {
        public string TipoPss { get; set; }
        public long CodigoPss { get; set; }
        public long TipoCobertura { get; set; }
    }
}
