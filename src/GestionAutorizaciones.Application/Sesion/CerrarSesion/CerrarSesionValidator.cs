using FluentValidation;

namespace GestionAutorizaciones.Application.Sesion.CerrarSesion
{
    public class CerrarSesionValidator : AbstractValidator<CerrarSesionCommand>
    {
        public CerrarSesionValidator()
        {
            RuleFor(t => t.NumeroSesion).NotEmpty();
        }
    }
}
