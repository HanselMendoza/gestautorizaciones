using FluentValidation;

namespace GestionAutorizaciones.Application.Autorizaciones.CompararAutorizacion
{
    public class CompararAutorizacionCommandValidator : AbstractValidator<CompararAutorizacionCommand>
    {
        public CompararAutorizacionCommandValidator()
        {
            RuleFor(x => x.Autorizaciones).NotEmpty();
        }
    }
}
