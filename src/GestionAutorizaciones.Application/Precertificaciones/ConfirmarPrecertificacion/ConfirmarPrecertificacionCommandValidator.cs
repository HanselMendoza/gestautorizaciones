using FluentValidation;

namespace GestionAutorizaciones.Application.Precertificaciones.ConfirmarPrecertificacion
{
    public class ConfirmarPrecertificacionCommandValidator : AbstractValidator<ConfirmarPrecertificacionCommand>
    {
        public ConfirmarPrecertificacionCommandValidator()
        {
            RuleFor(t => t.NumeroPrecertificacion).NotEmpty();
        }
    }
}

