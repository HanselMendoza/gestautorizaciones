using System.Threading;
using System.Threading.Tasks;
using GestionAutorizaciones.API.Utils;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using GestionAutorizaciones.API.Attributes;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.Application.Common.Dtos;
using Microsoft.AspNetCore.Http;
using GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado;
using System;

namespace GestionAutorizaciones.API.Controllers
{
    [RequiereTokenUsuario]
    [ApiVersion(ApiVersions.v1)]
    [Route(Routes.GenericController)]
    public class AseguradoController : ApiController
    {
        [RequierePermiso(Permiso.LeerAfiliado)]
        [HttpGet("{numeroPlastico}")]
        [SwaggerOperation(Summary = "Validar y obtener información de asegurado por número de plástico.")]
        [ProducesResponseType(typeof(ResponseDto<ObtenerAseguradoResponseDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> ObtenerAsegurado(long numeroPlastico, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion, CancellationToken cancellationToken)
        {
            var query = new ObtenerAseguradoQuery
            {
                NumeroPlastico = numeroPlastico,
                NumeroSesion = numeroSesion,
                TipoPss = Usuario.Config.Role, 
                CodigoPss = Convert.ToInt32(Usuario.Config.Id)
            };

            var result = await Mediator.Send(query, cancellationToken);
            return Ok(result);
        }
    }
}