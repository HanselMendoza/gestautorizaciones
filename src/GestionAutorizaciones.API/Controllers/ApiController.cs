using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using GestionAutorizaciones.API.Utils;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Auth.Common;

namespace GestionAutorizaciones.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(RespuestaDto), StatusCodes.Status400BadRequest)]
    public class ApiController : ControllerBase
    {
        private IMediator _mediator;
        protected IMediator Mediator => _mediator ??= HttpContext.RequestServices.GetService<IMediator>();

        protected ClienteConfig ClienteConfig => (ClienteConfig) HttpContext.Items[HttpContextItems.ClienteConfig];
        protected Usuario Usuario => (Usuario) HttpContext.Items[nameof(Application.Auth.Common.Usuario)];
    }
}
