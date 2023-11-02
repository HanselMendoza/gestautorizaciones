using AutoMapper;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using Microsoft.AspNetCore.Http;
using System;
using GestionAutorizaciones.Application.Prestadores.Common;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerPrestador
{
    public class ObtenerPrestadorQueryHandler : IRequestHandler<ObtenerPrestadorQuery, ResponseDto<ObtenerPrestadorResponseDto>>
    {
        private readonly IMapper _mapper;
        private readonly IPrestadorRepositorio _prestadorRepositorio;

        public ObtenerPrestadorQueryHandler(IMapper mapper, IPrestadorRepositorio prestadorRepositorio)
        {
            _mapper = mapper;
            _prestadorRepositorio = prestadorRepositorio;
        }

        public async Task<ResponseDto<ObtenerPrestadorResponseDto>> Handle(ObtenerPrestadorQuery request, CancellationToken cancellationToken)
        {
            try
            {

                var result = await _prestadorRepositorio.ObtenerInfoPss(tipoPss: request.TipoPss, codigoPss: request.CodigoPss);

                if (result == null)
                {
                    return new ResponseDto<ObtenerPrestadorResponseDto>(new ObtenerPrestadorResponseDto { Prestador = null },
                        StatusCodes.Status204NoContent, DescripcionRespuesta.NoContent);
                }
                var prestador = _mapper.Map<PrestadorDTO>(result);
                ObtenerPrestadorResponseDto pssResponseDto = new ObtenerPrestadorResponseDto { Prestador = prestador };
                return new ResponseDto<ObtenerPrestadorResponseDto>(pssResponseDto, StatusCodes.Status200OK, DescripcionRespuesta.OK);

            }
            catch (Exception e)
            {
                return new ResponseDto<ObtenerPrestadorResponseDto>(new ObtenerPrestadorResponseDto { Prestador = null },
                    StatusCodes.Status500InternalServerError, e.StackTrace);
            }

        }
    }
}
