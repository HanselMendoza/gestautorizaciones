using System;
using Microsoft.AspNetCore.Mvc.Filters;
using GestionAutorizaciones.API.Utils;
using GestionAutorizaciones.API.Exceptions;
namespace GestionAutorizaciones.API.Attributes
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
    public class RequiereSesionAttribute : ActionFilterAttribute
    {
        public RequiereSesionAttribute() {}

        public override void OnActionExecuting(ActionExecutingContext context)
        {
            if (!context.HttpContext.Request.Headers.TryGetValue(HeaderConstants.NumeroSesion, out var numeroSesion))
                throw new UnauthorizedException($"Se requiere especificar header {HeaderConstants.NumeroSesion}");

            if (string.IsNullOrWhiteSpace(numeroSesion))
                throw new UnauthorizedException($"Debe especificar valor header {HeaderConstants.NumeroSesion}");
            
            base.OnActionExecuting(context);
        }
    }
}