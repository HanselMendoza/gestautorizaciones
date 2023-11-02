using GestionAutorizaciones.API.Attributes;
using GestionAutorizaciones.API.Utils;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Diagnosticos.ObtenerDiagnosticos;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using System.Threading;
using System.Threading.Tasks;

namespace GestionAutorizaciones.API.Controllers
{
	[RequiereTokenUsuario]
	[ApiVersion(ApiVersions.v1)]
	[Route(Routes.GenericController)]
	public class DiagnosticosController : ApiController
	{
		[HttpGet]
		[SwaggerOperation(Summary = "Obtener diagnosticos")]
		[ProducesResponseType(typeof(PaginacionDto<ObtenerDiagnosticosResponseDto>), StatusCodes.Status200OK)]
		public async Task<IActionResult> ObtenerDiagnosticos(string buscar, int pagina = 1, int tamanio = 20, CancellationToken cancellationToken = default)
		{
			var result = await Mediator.Send(new ObtenerDiagnosticosQuery(buscar, pagina, tamanio), cancellationToken);
			return Ok(result);
		}
	}
}
