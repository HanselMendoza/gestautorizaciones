using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using Microsoft.AspNetCore.Http;
using System;
using GestionAutorizaciones.Application.Prestadores.Common;

namespace GestionAutorizaciones.Application.Prestadores.ValidarPssPuedeOfrecerServicio
{

    public class ValidarPssOfreceCoberturaQueryHandler : IRequestHandler<ValidarPssOfreceCoberturaQuery, ResponseDto<ValidarPssOfreceCoberturaResponseDto>>
    {
        private readonly IPrestadorRepositorio _prestadorRepositorio;

        public ValidarPssOfreceCoberturaQueryHandler(IPrestadorRepositorio prestadorRepositorio)
        {
            _prestadorRepositorio = prestadorRepositorio;
        }

        public async Task<ResponseDto<ValidarPssOfreceCoberturaResponseDto>> Handle(ValidarPssOfreceCoberturaQuery request, CancellationToken cancellationToken)
        {

            try
            {
                var result = await _prestadorRepositorio.ValidarPrestadorOfreceTipoCobertra(tipoPss: request.TipoPss,
                    codigoPss: request.CodigoPss, tipoCobertura: request.TipoCobertura);

                if (result == null || result.Aplica == null)
                {

                    return new ResponseDto<ValidarPssOfreceCoberturaResponseDto>(new ValidarPssOfreceCoberturaResponseDto { Aplica = null },
                             StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);
                }


                return new ResponseDto<ValidarPssOfreceCoberturaResponseDto>(new ValidarPssOfreceCoberturaResponseDto { Aplica = result.Aplica },
                        StatusCodes.Status200OK, DescripcionRespuesta.OK);
            }
            catch (Exception e)
            {
                return new ResponseDto<ValidarPssOfreceCoberturaResponseDto>(new ValidarPssOfreceCoberturaResponseDto { Aplica = null },
                    StatusCodes.Status500InternalServerError, e.StackTrace);
            }

        }

    }

}


