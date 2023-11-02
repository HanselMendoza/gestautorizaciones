using FluentValidation;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerPrestador
{
    public class ObtenerPrestadorQueryValidator : AbstractValidator<ObtenerPrestadorQuery>
    {
        public ObtenerPrestadorQueryValidator()
        {
            RuleFor(x => x.TipoPss).NotEmpty();
            RuleFor(x => x.CodigoPss).NotEmpty();
        }
    }
}
