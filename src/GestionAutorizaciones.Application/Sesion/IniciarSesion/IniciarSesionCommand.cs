using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;

namespace GestionAutorizaciones.Application.Sesion.IniciarSesion
{
    public class IniciarSesionCommand : IRequest<ResponseDto<IniciarSesionResponseDto>>
    {
        public long Codigo { get; set; }
        public long Pin { get; set; }
    }
}
