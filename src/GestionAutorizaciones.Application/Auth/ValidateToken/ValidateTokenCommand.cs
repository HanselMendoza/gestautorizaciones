using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Auth.ValidateToken
{
    public class ValidateTokenCommand : IRequest<ResponseDto<ValidateTokenResponseDto>>
    {
        public string AccessToken { get; set; }

        public string ClientId { get; set; }
        public string ApiKey { get; set; }
    }
}
