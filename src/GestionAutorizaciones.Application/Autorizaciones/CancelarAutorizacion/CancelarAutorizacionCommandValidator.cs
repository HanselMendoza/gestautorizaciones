using FluentValidation;

namespace GestionAutorizaciones.Application.Autorizaciones.CancelarAutorizacion
{
    public class CancelarAutorizacionCommandValidator : AbstractValidator<CancelarAutorizacionCommand>
    {
        public CancelarAutorizacionCommandValidator()
        {
            RuleFor(x => x.NumeroAutorizacion).NotEmpty();
            RuleFor(x => x.NumeroPlastico).NotEmpty();
            RuleFor(x => x.CodigoMotivo).IsInEnum();
        }
    }
}

