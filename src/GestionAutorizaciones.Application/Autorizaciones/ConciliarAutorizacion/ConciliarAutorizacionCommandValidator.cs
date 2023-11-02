using FluentValidation;

namespace GestionAutorizaciones.Application.Autorizaciones.ConciliarAutorizacion
{
    public class ConciliarAutorizacionCommandValidator : AbstractValidator<ConciliarAutorizacionCommand>
    {
        public ConciliarAutorizacionCommandValidator()
        {
            RuleFor(x => x.FechaInicio).NotEmpty();
            RuleFor(x => x.FechaFin).NotEmpty();
            RuleFor(x => x.Detalle).NotEmpty();
        }
    }
}
