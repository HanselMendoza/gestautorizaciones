using System;
namespace GestionAutorizaciones.API.Attributes
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
    public class RequiereTokenUsuarioAttribute : Attribute
    {
        public RequiereTokenUsuarioAttribute() {}
        public RequiereTokenUsuarioAttribute(string someValue) {}
    }
}