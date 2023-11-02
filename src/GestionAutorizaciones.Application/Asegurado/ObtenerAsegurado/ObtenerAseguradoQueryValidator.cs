using FluentValidation;

namespace GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado
{
    public class ObtenerAseguradoQueryValidator : AbstractValidator<ObtenerAseguradoQuery>
    {
        public ObtenerAseguradoQueryValidator()
        {
            RuleFor(t => t.NumeroPlastico).NotEmpty();
            RuleFor(t => t.NumeroSesion).NotEmpty();
        }
    }
}
