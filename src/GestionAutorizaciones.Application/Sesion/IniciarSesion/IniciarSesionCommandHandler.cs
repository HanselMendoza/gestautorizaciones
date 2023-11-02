using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;
using Microsoft.AspNetCore.Http;
using System;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;

namespace GestionAutorizaciones.Application.Sesion.IniciarSesion
{
    public class IniciarSesionCommandHandler : IRequestHandler<IniciarSesionCommand, ResponseDto<IniciarSesionResponseDto>>
    {
        private readonly ISesionRepositorio _gestionAutorizacionRepositorio;

        public IniciarSesionCommandHandler(ISesionRepositorio gestionAutorizacionRepositorio)
        {
            _gestionAutorizacionRepositorio = gestionAutorizacionRepositorio;
        }

        public async Task<ResponseDto<IniciarSesionResponseDto>> Handle(IniciarSesionCommand request, CancellationToken cancellationToken)
        {

            try
            {
                var resultSesion = await _gestionAutorizacionRepositorio.Infoxproc(NombreOperacion.AbrirSesion, 0, null, null, 0, 0);

                if (resultSesion == null || resultSesion.Outnum2 == null)
                {
                    return new ResponseDto<IniciarSesionResponseDto>(new IniciarSesionResponseDto { NumeroSesion = null },
                        StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

                var resultValidar = await _gestionAutorizacionRepositorio.Infoxproc(NombreOperacion.ValidarPin, long.Parse(resultSesion.Outnum2),
                    Convert.ToString(request.Codigo), Convert.ToString(request.Pin), 0, 0);


                if (resultValidar.Outnum1 == RespuestaInfoxprocPin.PinNoValido)
                {
                    return new ResponseDto<IniciarSesionResponseDto>(new IniciarSesionResponseDto { NumeroSesion = null },
                        int.Parse(resultValidar.Outnum1), MensajeInfoxproc.PinNoValido);
                }

                if (resultValidar.Outnum1 == RespuestaInfoxprocPin.PinNoAsignado)
                {
                    return new ResponseDto<IniciarSesionResponseDto>(new IniciarSesionResponseDto { NumeroSesion = null },
                        int.Parse(resultValidar.Outnum1), MensajeInfoxproc.PinNoAsignado);
                }


                if (resultValidar.Outnum1 == RespuestaInfoxprocPin.PinValido)
                {
                    return new ResponseDto<IniciarSesionResponseDto>(new IniciarSesionResponseDto { NumeroSesion = long.Parse(resultSesion.Outnum2) },
                        StatusCodes.Status200OK, DescripcionRespuesta.OK);
                }
                else
                {
                    return new ResponseDto<IniciarSesionResponseDto>(new IniciarSesionResponseDto { NumeroSesion = null },
                        StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }

            }
            catch (Exception e)
            {
                return new ResponseDto<IniciarSesionResponseDto>(new IniciarSesionResponseDto { NumeroSesion = null },
                    StatusCodes.Status500InternalServerError, e.StackTrace);
            }

        }

    }
}
