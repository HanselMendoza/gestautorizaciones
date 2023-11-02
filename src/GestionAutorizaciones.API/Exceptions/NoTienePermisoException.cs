using System;
namespace GestionAutorizaciones.API.Exceptions
{
    public class NoTienePermisoException : Exception
    {
        public NoTienePermisoException(string permiso) : base (string.Format("El usuario no está autorizado a consumir este método {0}", permiso)) {}
        public override string StackTrace => $"{nameof(NoTienePermisoException)}: {Message}";
    }
}