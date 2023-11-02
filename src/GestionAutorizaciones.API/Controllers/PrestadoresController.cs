
using System.Threading;
using System.Threading.Tasks;
using GestionAutorizaciones.API.Utils;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using GestionAutorizaciones.API.Attributes;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.Application.Prestadores.ObtenerPrestador;
using GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidos;
using GestionAutorizaciones.Application.Prestadores.ValidarPssPuedeOfrecerServicio;
using System;
using Microsoft.AspNetCore.Http;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidosNoServicio;

namespace GestionAutorizaciones.API.Controllers
{

    [RequiereTokenUsuario]
    [ApiVersion(ApiVersions.v1)]
    [Route(Routes.GenericController)]

    public class PrestadoresController : ApiController
    {
        [RequierePermiso(Permiso.LeerPrestador)]
        [HttpGet("yo")]
        [SwaggerOperation(Summary = "Obtener información de un Prestador.")]
        [ProducesResponseType(typeof(ResponseDto<ObtenerPrestadorResponseDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> ObtenerPrestador(CancellationToken cancellationToken)
        {
            var query = new ObtenerPrestadorQuery
            {
                TipoPss = Usuario.Config.Role,
                CodigoPss = Convert.ToInt64(Usuario.Config.Id)
            };
            var result = await Mediator.Send(query, cancellationToken);
            return Ok(result);
        }

        [RequierePermiso(Permiso.LeerTipoCobertura)]
        [HttpGet("yo/tipocobertura/validacion")]
        [SwaggerOperation(Summary = "Validar si el prestador puede ofrecer el tipo de cobertura.")]
        [ProducesResponseType(typeof(ResponseDto<ValidarPssOfreceCoberturaResponseDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> ValidarPssOfreceCobertura(long tipoCobertura, CancellationToken cancellationToken)
        {
            var query = new ValidarPssOfreceCoberturaQuery
            {
                TipoPss = Usuario.Config.Role,
                CodigoPss = Convert.ToInt64(Usuario.Config.Id),
                TipoCobertura = tipoCobertura
            };
            var result = await Mediator.Send(query, cancellationToken);
            return Ok(result);

        }

        [RequierePermiso(Permiso.LeerProcedimientosPermitidos)]
        [HttpGet("yo/procedimientos")]
        [SwaggerOperation(Summary = "Obtener procedimientos permitidos de un Prestador.")]
        [ProducesResponseType(typeof(ResponseDto<ObtenerProcedimientosPermitidosResponseDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> ObtenerProcedimientosPermitidos(long? cobertura, string nombreCobertura,
            int pagina, int tamanoPagina, long? servicio, CancellationToken cancellationToken = default)
        {
            var query = new ObtenerProcedimientosPermitidosQuery
            {
                TipoPss = Usuario.Config.Role,
                CodigoPss = Convert.ToInt64(Usuario.Config.Id),
                Cobertura = cobertura,
                NombreCobertura = nombreCobertura,
                Pagina = pagina,
                TamanoPagina = tamanoPagina,
                Servicio = servicio,
            };
            var result = await Mediator.Send(query, cancellationToken);
            return Ok(result);

        }

        [RequierePermiso(Permiso.LeerProcedimientosPermitidos)]
        [HttpGet("yo/procedimientos/catalogo")]
        [SwaggerOperation(Summary = "Obtener procedimientos permitidos de un Prestador.")]
        [ProducesResponseType(typeof(ResponseDto<ObtenerProcedimientosPermitidosResponseDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> ObtenerProcedimientosPermitidosNoServicio(long? cobertura, string nombreCobertura,
            int pagina, int tamanoPagina, long? servicio, CancellationToken cancellationToken = default)
        {
            var query = new ObtenerProcedimientosPermitidosNoServicioQuery
            {
                TipoPss = Usuario.Config.Role,
                CodigoPss = Convert.ToInt64(Usuario.Config.Id),
                Cobertura = cobertura,
                NombreCobertura = nombreCobertura,
                Pagina = pagina,
                TamanoPagina = tamanoPagina,
                Servicio = servicio,
            };
            var result = await Mediator.Send(query, cancellationToken);
            return Ok(result);

        }
    }
}

