using FluentValidation;

namespace GestionAutorizaciones.Application.Procedimientos.EliminarProcedimiento
{
    public class EliminarProcedimientoCommandValidator : AbstractValidator<EliminarProcedimientoCommand>
    {
        public EliminarProcedimientoCommandValidator()
        {
            RuleFor(x => x.Procedimiento).NotEmpty();
        }
    }
}

