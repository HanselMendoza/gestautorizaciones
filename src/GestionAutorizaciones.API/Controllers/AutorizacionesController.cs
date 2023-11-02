using GestionAutorizaciones.API.Utils;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using System.Collections.Generic;
using System.Threading.Tasks;
using GestionAutorizaciones.API.Attributes;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.Application.Common.Dtos;
using Microsoft.AspNetCore.Http;
using GestionAutorizaciones.Application.Autorizaciones.ObtenerAutorizaciones;
using GestionAutorizaciones.Application.Autorizaciones.CancelarAutorizacion;
using GestionAutorizaciones.Application.Autorizaciones.CompararAutorizacion;
using GestionAutorizaciones.Application.Autorizaciones.ConciliarAutorizacion;
using System;
using GestionAutorizaciones.Application.Autorizaciones.ObtenerDetalleAutorizacion;
using GestionAutorizaciones.Application.Autorizaciones.ProcesarAutorizacion;

namespace GestionAutorizaciones.API.Controllers
{
    [RequiereTokenUsuario]
    [ApiVersion(ApiVersions.v1)]
    public class AutorizacionesController : ApiController
    {
        [RequierePermiso(Permiso.LeerAutorizaciones)]
        [HttpGet]
        [SwaggerOperation(Summary = "Obtener listado de autorizaciones.")]
        [ProducesResponseType(typeof(ResponseDto<ObtenerAutorizacionesResponseDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> ObtenerAutorizaciones([FromQuery] ObtenerAutorizacionesRequest request)
        {
            var query = new ObtenerAutorizacionesQuery {
                TipoPss = Usuario.Config.Role,
                CodigoPss = Convert.ToInt64(Usuario.Config.Id),
                Ramo = request.Ramo,
                Secuencial = request.Secuencial,
                NumeroPlastico = request.NumeroPlastico,
                FechaInicio = request.FechaInicio,
                FechaFin = request.FechaFin,
                Pagina = request.Pagina,
                TamanoPagina = request.TamanoPagina,
                UsuarioIngreso = request.UsuarioIngreso,
                Compania = request.Compania
            };
            var result = await Mediator.Send(query);
            return Ok(result);
        }

        [RequierePermiso(Permiso.LeerAutorizacion)]
        [HttpGet("{numeroAutorizacion}")]
        [SwaggerOperation(Summary = "Obtener detalle de una autorización.")]
        public async Task<IActionResult> ObtenerDetalleAutorizacion(string numeroAutorizacion, [FromQuery]int? ano)
        {
            var query = new ObtenerDetalleAutorizacionQuery
            {
                NumeroAutorizacion = numeroAutorizacion,
                TipoPss = Usuario.Config.Role, 
                CodigoPss = Convert.ToInt32(Usuario.Config.Id),
                Ano = ano
            };
            return Ok(await Mediator.Send(query));
        }

        [RequierePermiso(Permiso.CancelarAutorizacion)]
        [HttpPost("{numeroAutorizacion}/cancelacion")]
        [SwaggerOperation(Summary = "Cancelar una autorización.")]
        public async Task<IActionResult> CancelarAutorizacion([FromRoute] string numeroAutorizacion, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion, [FromBody] CancelarAutorizacionCommand command)
        {
            command.NumeroAutorizacion = numeroAutorizacion;
            command.NumeroSesion = numeroSesion;
            command.UsuarioIngresa ??= ClienteConfig?.NombreCliente?.ToUpper();
            return Ok(await Mediator.Send(command));
        }

        [RequierePermiso(Permiso.ConciliarAutorizaciones)]
        [HttpPost("conciliacion")]
        [SwaggerOperation(Summary = "Conciliar autorizaciones.")]
        public async Task<IActionResult> ConciliarAutorizaciones([FromBody] ConciliarAutorizacionCommand command,
            [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            command.NumeroSesion = numeroSesion;
            return Ok(await Mediator.Send(command));
        }

        [RequierePermiso(Permiso.CompararAutorizaciones)]
        [HttpPost("comparacion")]
        [SwaggerOperation(Summary = "Comparar autorizaciones.")]
        public async Task<IActionResult> CompararAutorizaciones([FromBody] List<Autorizacion> autorizaciones,
            [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            var command = new CompararAutorizacionCommand
            {
                Autorizaciones = autorizaciones,
                NumeroSesion = numeroSesion
            };
            return Ok(await Mediator.Send(command));
        }

        [HttpPost("procesar")]
        [SwaggerOperation(Summary = "Procesar autorizacion.")]
        public async Task<IActionResult> ProcesarAutorizacion([FromBody] ProcesarAutorizacionCommand command,[FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            command.NumeroSesion = numeroSesion;
            command.UsuarioRegistra ??= ClienteConfig?.UsuarioIngresoReclamacion;
            return Ok(await Mediator.Send(command));
        }

    }
}