using FluentValidation;

namespace GestionAutorizaciones.Application.Autorizaciones.ObtenerDetalleAutorizacion
{
    public class ObtenerDetalleAutorizacionQueryValidator : AbstractValidator<ObtenerDetalleAutorizacionQuery>
    {
        public ObtenerDetalleAutorizacionQueryValidator()
        {
            RuleFor(x => x.NumeroAutorizacion).NotEmpty();
        }
    }
}

