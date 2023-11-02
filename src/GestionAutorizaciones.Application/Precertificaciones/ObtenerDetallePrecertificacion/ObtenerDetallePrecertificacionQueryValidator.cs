using FluentValidation;

namespace GestionAutorizaciones.Application.Precertificaciones.ObtenerDetallePrecertificacion
{
    public class ObtenerDetallePrecertificacionQueryValidator : AbstractValidator<ObtenerDetallePrecertificacionQuery>
    {
        public ObtenerDetallePrecertificacionQueryValidator()
        {
            RuleFor(t => t.NumeroPrecertificacion).NotEmpty();
            RuleFor(t => t.Compania).NotEmpty();
        }
    }
}

