using GestionAutorizaciones.API.Utils;
using GestionAutorizaciones.API.Attributes;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Procedimientos.InsertarProcedimiento;
using GestionAutorizaciones.Application.Procedimientos.ValidarProcedimiento;
using GestionAutorizaciones.Application.Procedimientos.EliminarProcedimiento;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using Swashbuckle.AspNetCore.Annotations;
using GestionAutorizaciones.Application.Procedimientos.ValidarConsulta;

namespace GestionAutorizaciones.API.Controllers
{
    [RequiereTokenUsuario]
    [ApiVersion(ApiVersions.v1)]
    [Route(Routes.GenericController)]
    [Produces("application/json")]
    [ProducesResponseType(typeof(RespuestaDto), StatusCodes.Status400BadRequest)]

    public class ProcedimientosController : ApiController
    {
        [HttpPost("consulta")]
        [RequierePermiso(Permiso.ValidarProcedimiento)]
        [SwaggerOperation(Summary = "Validar Consulta")]
        [ProducesResponseType(typeof(ResponseDto<ValidarConsultaResponseDto>), StatusCodes.Status200OK)]

        public async Task<IActionResult> ValidarConsulta(ValidarConsultaCommand command, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            command.NumeroSesion = numeroSesion;
            command.UsuarioRegistra ??= ClienteConfig?.UsuarioIngresoReclamacion;
            var respuestaDto = await Mediator.Send(command);
            return Ok(respuestaDto);
        }

        [HttpPost]
        [RequierePermiso(Permiso.InsertarProcedimiento)]
        [SwaggerOperation(Summary = "Insertar procedimiento.")]
        [ProducesResponseType(typeof(ResponseDto<InsertarProcedimientoResponseDto>),StatusCodes.Status200OK)]
        public async Task<IActionResult> InsertarProcedimiento(InsertarProcedimientoCommand command, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            command.NumeroSesion = numeroSesion;
            command.UsuarioRegistra ??= ClienteConfig?.UsuarioIngresoReclamacion;
            var result = await Mediator.Send(command);
            return Ok(result);
        }

        [HttpPost("validacion")]
        [RequierePermiso(Permiso.ValidarProcedimiento)]
        [SwaggerOperation(Summary = "Validar procedimiento.")]
        [ProducesResponseType(typeof(ResponseDto<ValidarProcedimientoResponseDto>),StatusCodes.Status200OK)]
        
        public async Task<IActionResult> ValidarProcedimiento(ValidarProcedimientoCommand command, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            command.NumeroSesion = numeroSesion;
            command.UsuarioRegistra ??= ClienteConfig?.UsuarioIngresoReclamacion;
            var respuestaDto = await Mediator.Send(command);
            return Ok(respuestaDto);
        }

        [HttpDelete("{codigoProcedimiento}")]
        [RequierePermiso(Permiso.CancelarProcedimiento)]
        [SwaggerOperation(Summary = "Cancelar/eliminar un procedimiento.")]
        [ProducesResponseType(typeof(ResponseDto<EliminarProcedimientoResponseDto>),StatusCodes.Status200OK)]
        public async Task<IActionResult> CancelarProcedimiento(long codigoProcedimiento, [FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            var request = new EliminarProcedimientoCommand { Procedimiento = codigoProcedimiento, NumeroSesion = numeroSesion };
            var respuestaDto = await Mediator.Send(request);
            return Ok(respuestaDto);
        }

        [HttpDelete("ultimo")]
        [RequierePermiso(Permiso.CancelarProcedimiento)]
        [SwaggerOperation(Summary = "Elimina el ultimo procedimiento agregado.")]
        [ProducesResponseType(typeof(ResponseDto<EliminarProcedimientoResponseDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> EliminaUltimoProcedimiento([FromHeader(Name = HeaderConstants.NumeroSesion)] long numeroSesion)
        {
            var request = new EliminarProcedimientoCommand { NumeroSesion = numeroSesion };
            var respuestaDto = await Mediator.Send(request);
            return Ok(respuestaDto);
        }
    }
}
