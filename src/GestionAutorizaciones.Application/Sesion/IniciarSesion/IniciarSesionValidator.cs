using FluentValidation;

namespace GestionAutorizaciones.Application.Sesion.IniciarSesion
{
    public class IniciarSesionValidator : AbstractValidator<IniciarSesionCommand>
    {
        public IniciarSesionValidator()
        {
            RuleFor(t => t.Codigo).NotEmpty();
            RuleFor(t => t.Pin).NotEmpty();
        }
    }
}
