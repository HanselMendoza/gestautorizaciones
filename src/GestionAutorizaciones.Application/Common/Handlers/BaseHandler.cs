using System.Threading;
using System.Threading.Tasks;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;
using Microsoft.AspNetCore.Http;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;

namespace GestionAutorizaciones.Application.Common.Handlers  {

    public abstract class BaseHandler<TCommand, TResponse>
    : IRequestHandler<TCommand, ResponseDto<TResponse>> where TCommand : IRequest<ResponseDto<TResponse>>
    {
        public abstract Task<ResponseDto<TResponse>> Handle(TCommand request, CancellationToken cancellationToken);

        protected ResponseDto<TResponse> Success(TResponse response) {
            return new ResponseDto<TResponse>(response, CodigoRespuesta.OK, DescripcionRespuesta.OK);
        }

        protected ResponseDto<TResponse> Error(int codigo, string mensaje = null) {
            return new ResponseDto<TResponse>(default, codigo, mensaje);
        }
    }
}