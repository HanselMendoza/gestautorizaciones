using FluentValidation;

namespace GestionAutorizaciones.Application.Autorizaciones.ProcesarAutorizacion
{
    public class ProcesarAutorizacionCommandValidator: AbstractValidator<ProcesarAutorizacionCommand>
    {

        public ProcesarAutorizacionCommandValidator()
        {
            RuleFor(x => x.NumeroPlastico).NotEmpty();
            RuleFor(x => x.Medicamentos).NotEmpty();
        }
    }
}
