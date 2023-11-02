using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Auth.Common;

namespace GestionAutorizaciones.Application.Auth.Login
{
    public class LoginCommandHandler : IRequestHandler<LoginCommand, ResponseDto<TokenGeneratedDto>>
    {
        private readonly IAuthService _authService;

        public LoginCommandHandler(IAuthService authService)
        {
            _authService = authService;
        }
        public async Task<ResponseDto<TokenGeneratedDto>> Handle(LoginCommand request, CancellationToken cancellationToken)
        {
            var (user, response) = await _authService.Login(request.ClientId, request.ApiKey, request.Username, request.Password);

            return new ResponseDto<TokenGeneratedDto>(
                new TokenGeneratedDto { AccessToken = user?.AccessToken, RefreshToken = user?.RefreshToken },
                response.Code ?? 1, response.Message);
        }

    }
}
