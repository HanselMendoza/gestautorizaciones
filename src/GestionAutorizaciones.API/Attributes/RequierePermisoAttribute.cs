using System;
using System.Linq;
using Microsoft.AspNetCore.Mvc.Filters;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.API.Utils;
using GestionAutorizaciones.API.Exceptions;
using GestionAutorizaciones.Application.Auth.Common;

namespace GestionAutorizaciones.API.Attributes
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
    public class RequierePermisoAttribute : ActionFilterAttribute
    {
        private readonly string _permiso;

        public RequierePermisoAttribute(Permiso permiso) { _permiso = permiso.ToString(); }

        public override void OnActionExecuting(ActionExecutingContext context)
        {
            var clienteConfig = (ClienteConfig) context.HttpContext.Items[HttpContextItems.ClienteConfig];
            
            if (!clienteConfig.Permisos.Any(p => p.ToLower() == _permiso.ToLower()))
            {
                throw new NoTienePermisoException(_permiso);
            }
            
            base.OnActionExecuting(context);
        }
    }
}