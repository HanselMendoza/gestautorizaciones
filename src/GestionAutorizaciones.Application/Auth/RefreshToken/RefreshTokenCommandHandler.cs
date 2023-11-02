using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Http;
using GestionAutorizaciones.Application.Common.Dtos;
using AuthenticationAPI.Driver;
using GestionAutorizaciones.Application.Auth.Common;

namespace GestionAutorizaciones.Application.Auth.RefreshToken
{
    public class RefreshTokenCommandHandler : IRequestHandler<RefreshTokenCommand, ResponseDto<TokenGeneratedDto>>
    {
        private readonly IAuthService _authService;

        public RefreshTokenCommandHandler(IAuthService authService)
        {
            _authService = authService;
        }

        public async Task<ResponseDto<TokenGeneratedDto>> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
        {
            var (user, response) = await _authService.RefreshToken(request.ClientId, request.ApiKey, request.ExpiredToken, request.RefreshToken);

            return new ResponseDto<TokenGeneratedDto>(
                new TokenGeneratedDto
                { AccessToken = user?.AccessToken, RefreshToken = user?.RefreshToken },
                 response.Code ?? 1, response.Message);
        }

    }
}
