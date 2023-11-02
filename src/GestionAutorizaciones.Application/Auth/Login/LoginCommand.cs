using System.Text.Json.Serialization;
using GestionAutorizaciones.Application.Auth.Common;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Auth.Login
{
    public class LoginCommand : IRequest<ResponseDto<TokenGeneratedDto>>
    {
        public string Username { get; set; }
        public string Password { get; set; }

        [JsonIgnore]
        public string ClientId { get; set; }
        [JsonIgnore]
        public string ApiKey { get; set; }
    }
}
