using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Auth.GetCurrentClient
{
    public class GetCurrentClientQuery : IRequest<ResponseDto<GetCurrentClientResponseDto>>
    {
        public string ClientId { get; set; }
        public string ApiKey { get; set; }
    }
}
