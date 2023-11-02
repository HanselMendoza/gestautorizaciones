using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Auth.Common;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Auth.RefreshToken
{
    public class RefreshTokenCommand : IRequest<ResponseDto<TokenGeneratedDto>>
    {
        public string ExpiredToken { get; set; }
        public string RefreshToken { get; set; }

        [JsonIgnore]
        public string ClientId { get; set; }
        [JsonIgnore]
        public string ApiKey { get; set; }
    }
}
