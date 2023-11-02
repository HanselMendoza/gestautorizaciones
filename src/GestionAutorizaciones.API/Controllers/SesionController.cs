using System.Threading.Tasks;
using GestionAutorizaciones.API.Utils;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using GestionAutorizaciones.API.Attributes;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.Application.Sesion.CerrarSesion;
using GestionAutorizaciones.Application.Sesion.IniciarSesion;
using GestionAutorizaciones.Application.Sesion.ReactivarSesion;
using GestionAutorizaciones.Application.Auth.Common;
using System;

namespace GestionAutorizaciones.API.Controllers
{

    [ApiVersion(ApiVersions.v1)]
    [Route(Routes.GenericController)]
    public class SesionController : ApiController
    {
        [RequierePermiso(Permiso.IniciarSesion)]
        [HttpPost("inicio")]
        [SwaggerOperation(Summary = "Inicio de sesión.")]
        public async Task<ActionResult<IniciarSesionResponseDto>> IniciarSesion([FromBody] IniciarSesionCommand command)
        {
            return Ok(await Mediator.Send(command));
        }

        [RequierePermiso(Permiso.CerrarSesion)]
        [HttpPost("cierre")]
        [SwaggerOperation(Summary = "Cierre de sesión.")]
        public async Task<IActionResult> CerrarSesion([FromBody] CerrarSesionCommand command, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            command.NumeroSesion = numeroSesion;
            return Ok(await Mediator.Send(command));
        }

        [RequiereTokenUsuario]
        [RequierePermiso(Permiso.ReactivarSesion)]
        [HttpPost("reinicio")]
        [SwaggerOperation(Summary = "Reactivar sesión.")]
        public async Task<IActionResult> ReactivarSesion([FromBody] ReactivarSesionCommand command)
        {
            command.CodigoPss = Convert.ToInt64(Usuario.Config.Id);
            return Ok(await Mediator.Send(command));
        }
    }
}

