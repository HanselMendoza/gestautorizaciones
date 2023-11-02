using System;
using FluentValidation;

namespace GestionAutorizaciones.Application.Prestadores.ValidarPssPuedeOfrecerServicio
{
    public class ValidarPssOfreceCoberturaValidator : AbstractValidator<ValidarPssOfreceCoberturaQuery>
    {
        public ValidarPssOfreceCoberturaValidator()
        {
            RuleFor(x => x.TipoPss).NotEmpty();
            RuleFor(x => x.CodigoPss).NotEmpty();
            RuleFor(x => x.TipoCobertura).NotEmpty();
        }
    }
}
