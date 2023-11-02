using FluentValidation;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidos
{
    public class ObtenerProcedimientosPermitidosValidator : AbstractValidator<ObtenerProcedimientosPermitidosQuery>
    {
        public ObtenerProcedimientosPermitidosValidator()
        {
            RuleFor(x => x.TipoPss).NotEmpty();
            RuleFor(x => x.CodigoPss).NotEmpty();
        }
    }
}
