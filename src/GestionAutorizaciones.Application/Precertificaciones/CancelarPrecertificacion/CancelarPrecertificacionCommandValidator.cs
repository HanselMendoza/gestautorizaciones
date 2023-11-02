using FluentValidation;
using GestionAutorizaciones.Application.Common.Enums;
using System;

namespace GestionAutorizaciones.Application.Precertificaciones.CancelarPrecertificacion
{
    public class CancelarPrecertificacionCommandValidator : AbstractValidator<CancelarPrecertificacionCommand>
    {
        public CancelarPrecertificacionCommandValidator()
        {
            RuleFor(comand => comand.NumeroPrecertificacion).NotEmpty();
            RuleFor(comand => comand.Compania)
                .NotNull().WithMessage("La compañia no es valida")
                .Must(compania => Enum.IsDefined(typeof(Compania), compania)).WithMessage("La compañia no es valida");
        }
    }
}
