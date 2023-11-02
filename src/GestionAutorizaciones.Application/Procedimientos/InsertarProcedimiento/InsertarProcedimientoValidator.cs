using FluentValidation;

namespace GestionAutorizaciones.Application.Procedimientos.InsertarProcedimiento
{
    public class InsertarProcedimientoValidator : AbstractValidator<InsertarProcedimientoCommand>
    {
        public InsertarProcedimientoValidator()
        {
            RuleFor(x => x.NumeroSesion).NotEmpty();
        }
    }
}
