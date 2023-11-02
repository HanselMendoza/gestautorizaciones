using System.Threading.Tasks;
using GestionAutorizaciones.API.Utils;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using GestionAutorizaciones.API.Attributes;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.Application.Common.Dtos;
using Microsoft.AspNetCore.Http;
using GestionAutorizaciones.Application.Auth.Login;
using GestionAutorizaciones.Application.Auth.RefreshToken;
using GestionAutorizaciones.Application.Auth.Common;

namespace GestionAutorizaciones.API.Controllers
{
    [ApiVersion(ApiVersions.v1)]
    [Route(Routes.GenericController)]
    [ProducesResponseType(typeof(ResponseDto<TokenGeneratedDto>), StatusCodes.Status200OK)]

    public class AuthController : ApiController
    {
        [RequierePermiso(Permiso.IniciarSesion)]
        [HttpPost("login")]
        [SwaggerOperation(Summary = "Login")]
        public async Task<IActionResult> Login([FromBody] LoginCommand command)
        {
            command.ClientId = ClienteConfig?.ClientId;
            command.ApiKey = ClienteConfig?.ApiKey;
            var result = await Mediator.Send(command);
            return Ok(result);
        }

        [HttpPost("refresh-token")]
        [SwaggerOperation(Summary = "Refrescar token")]
        public async Task<IActionResult> RefrescarToken([FromBody] RefreshTokenCommand command)
        {
            command.ClientId = ClienteConfig?.ClientId;
            command.ApiKey = ClienteConfig?.ApiKey;
            return Ok(await Mediator.Send(command));
        }
    }
}

