using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Http;
using GestionAutorizaciones.Application.Common.Dtos;
using AuthenticationAPI.Driver;
using GestionAutorizaciones.Application.Auth.Common;

namespace GestionAutorizaciones.Application.Auth.ValidateToken
{
    public class ValidateTokenCommandHandler : IRequestHandler<ValidateTokenCommand, ResponseDto<ValidateTokenResponseDto>>
    {
        private readonly IAuthService _authService;

        public ValidateTokenCommandHandler(IAuthService authService)
        {
            _authService = authService;
        }

        public async Task<ResponseDto<ValidateTokenResponseDto>> Handle(ValidateTokenCommand request, CancellationToken cancellationToken)
        {
            var (isValid, message) = await _authService.ValidateToken(request.ClientId, request.ApiKey, request.AccessToken);

            return new ResponseDto<ValidateTokenResponseDto>(
                new ValidateTokenResponseDto { IsValid = isValid }, isValid ? 0 : 1, message);
        }
    }
}
