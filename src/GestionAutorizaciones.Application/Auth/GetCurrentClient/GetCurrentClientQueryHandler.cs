using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using MediatR;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Auth.Common;

namespace GestionAutorizaciones.Application.Auth.GetCurrentClient
{
    public class GetCurrentClientQueryHandler : IRequestHandler<GetCurrentClientQuery, ResponseDto<GetCurrentClientResponseDto>>
    {
        private readonly IAuthService _authService;

        public GetCurrentClientQueryHandler(IAuthService authService)
        {
            _authService = authService;
        }

        public async Task<ResponseDto<GetCurrentClientResponseDto>> Handle(GetCurrentClientQuery request, CancellationToken cancellationToken)
        {
            var (client, response) = await _authService.GetCurrentClient(request.ClientId, request.ApiKey);

            var metadataDto = new List<ClientMetadataDto>();

            foreach (var meta in client.Metadata)
                metadataDto.Add(new ClientMetadataDto { Key = meta.Key, Value = meta.Value });

            return new ResponseDto<GetCurrentClientResponseDto>(
                new GetCurrentClientResponseDto
                {
                    ClientName = client.ClientName,
                    ClientId = client.ClientId,
                    IsExternal = client.IsExternal,
                    IsActive = client.IsActive,
                    Blocked = client.Blocked,
                    CurrentResource = client.CurrentResource,
                    Permissions = client.Permissions,
                    Metadata = metadataDto,
                }, response.Code ?? 1, response.Message);
        }
    }
}
