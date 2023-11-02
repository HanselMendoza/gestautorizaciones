using GestionAutorizaciones.API.Utils;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using System.Threading.Tasks;
using GestionAutorizaciones.API.Attributes;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.Application.Precertificaciones.ConfirmarPrecertificacion;
using GestionAutorizaciones.Application.Precertificaciones.ObtenerDetallePrecertificacion;
using GestionAutorizaciones.Application.Precertificaciones.CancelarPrecertificacion;
using System;

namespace GestionAutorizaciones.API.Controllers
{
    [RequiereTokenUsuario]
    [ApiVersion(ApiVersions.v1)]
    [Route(Routes.GenericController)]
    public class PrecertificacionesController : ApiController
    {

        [RequierePermiso(Permiso.ConfirmarPrecertificacion)]
        [HttpPost("{numeroPrecertificacion}/confirmacion")]
        [SwaggerOperation(Summary = "Confirmar una Pre-Certificación.")]
        public async Task<IActionResult> ConfirmarPrecertificacion(long numeroPrecertificacion, string usuarioIngresa, int compania, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            usuarioIngresa ??= ClienteConfig?.UsuarioIngresoReclamacion;
            return Ok(await Mediator.Send(new ConfirmarPrecertificacionCommand { Compania = compania, NumeroPrecertificacion = numeroPrecertificacion, NumeroSesion = numeroSesion, UsuarioRegistra = usuarioIngresa }));
        }

        [RequierePermiso(Permiso.LeerPrecertificacion)]
        [HttpGet("{numeroPrecertificacion}")]
        [SwaggerOperation(Summary = "Obtener detalle de una Pre-Certificación.")]
        public async Task<IActionResult> ObtenerDetallePrecertificacion(long numeroPrecertificacion, int compania, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            return Ok(await Mediator.Send(new ObtenerDetallePrecertificacionQuery
            {
                NumeroPrecertificacion = numeroPrecertificacion,
                Compania = compania,
                NumeroSesion = numeroSesion
            }));

        }

        [RequierePermiso(Permiso.CancelarPrecertificacion)]
        [HttpPost("{numeroPrecertificacion}/cancelacion")]
        [SwaggerOperation(Summary = "Cancelar una Pre-Certificación.")]
        public async Task<IActionResult> CancelarPrecertificacion(long numeroPrecertificacion, int compania, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            return Ok(await Mediator.Send(new CancelarPrecertificacionCommand
            {
                NumeroPrecertificacion = numeroPrecertificacion,
                Compania = compania,
                TipoPss = Usuario.Config.Role,
                CodigoPss = Convert.ToInt64(Usuario.Config.Id)
            }));

        }

    }
}
