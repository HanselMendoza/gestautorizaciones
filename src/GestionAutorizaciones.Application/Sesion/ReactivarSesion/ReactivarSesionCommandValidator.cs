using FluentValidation;

namespace GestionAutorizaciones.Application.Sesion.ReactivarSesion
{
    public class ReactivarSesionCommandValidator : AbstractValidator<ReactivarSesionCommand>
    {
        public ReactivarSesionCommandValidator()
        {
            RuleFor(t => t.NumeroAutorizacion).NotEmpty();
        }
    }
}

