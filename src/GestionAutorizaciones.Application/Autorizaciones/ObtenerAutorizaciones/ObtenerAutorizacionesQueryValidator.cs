using FluentValidation;

namespace GestionAutorizaciones.Application.Autorizaciones.ObtenerAutorizaciones
{
    public class ObtenerAutorizacionesQueryValidator : AbstractValidator<ObtenerAutorizacionesQuery>
    {
        public ObtenerAutorizacionesQueryValidator()
        {
            RuleFor(x => x.TipoPss).NotEmpty();
            RuleFor(x => x.CodigoPss).NotEmpty();
            RuleFor(x => x.FechaInicio).NotEmpty();
            RuleFor(x => x.FechaFin).NotEmpty();
        }
    }
}
