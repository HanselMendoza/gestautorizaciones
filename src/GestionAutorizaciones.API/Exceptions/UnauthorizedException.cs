using System;
namespace GestionAutorizaciones.API.Exceptions
{
    public class UnauthorizedException : Exception
    {
        public UnauthorizedException() {}
        public UnauthorizedException(string message) : base (message) {}

        public override string StackTrace => $"{nameof(UnauthorizedException)}: {Message}";
    }
}