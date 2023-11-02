using FluentValidation;

namespace GestionAutorizaciones.Application.Procedimientos.ValidarProcedimiento
{
    public class ValidarProcedimientoValidator : AbstractValidator<ValidarProcedimientoCommand>
    {
        public ValidarProcedimientoValidator()
        {
            RuleFor(x => x.CodigoProcedimiento).NotEmpty();
        }
    }
}
