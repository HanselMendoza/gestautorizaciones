using GestionAutorizaciones.Application.Autorizaciones.Common;
using GestionAutorizaciones.Application.Autorizaciones.ConciliarAutorizacion;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Common.Exceptions;
using GestionAutorizaciones.Application.Common.Utils;
using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Domain.Entities.Enums;
using GestionAutorizaciones.Domain.Entities;
using MediatR;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;
using AutoMapper;

namespace GestionAutorizaciones.Application.Autorizaciones.ProcesarAutorizacion
{
    public class ProcesarAutorizacionCommandHandler : IRequestHandler<ProcesarAutorizacionCommand, ResponseDto<ProcesarAutorizacionResponseDto>>
    {

        private readonly ISesionRepositorio _sesionRepositorio;
        private readonly IAutorizacionRepositorio _autorizacionRepositorio;
        private readonly IMapper _mapper;
        public ProcesarAutorizacionCommandHandler(
            ISesionRepositorio sesionRepositorio, 
            IAutorizacionRepositorio autorizacionRepositorio,
            IMapper mapper)
        {
            _sesionRepositorio = sesionRepositorio;
            _autorizacionRepositorio = autorizacionRepositorio;
            _mapper = mapper;
        }
        public async Task<ResponseDto<ProcesarAutorizacionResponseDto>> Handle(ProcesarAutorizacionCommand request, CancellationToken cancellationToken)
        {
            var sesion = await _sesionRepositorio.ObtenerInfoSesion(request.NumeroSesion.Value);

            if(sesion == null || sesion.DescripcionEstatus != Constantes.DescripcionEstatusSesion.Abierta)
                new ResponseDto<ProcesarAutorizacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);

            decimal montoArsSum = 0;
            decimal montoAseguradoSum = 0;

            // validar cobertura
            foreach (var medicamento in request.Medicamentos)
            {
                try
                {
                    var result = await _autorizacionRepositorio.ValidarCoberturaMedicina(request.NumeroSesion.Value, medicamento.CodigoSimon, medicamento.Descripcion, medicamento.Cantidad.Value, medicamento.Precio.Value);
                    // guardar montos en una variable
                    montoArsSum += result.montoArs;
                    montoAseguradoSum += result.montoAsegurado;
                }
                catch (Exception)
                {
                    throw new BusinessException($"Error al validar cobertura de medicamento: {medicamento.Descripcion}");
                }

            }

            // aqui hay que usar 
            var abrirReclamacion = await _sesionRepositorio.Infoxproc(Constantes.NombreOperacion.AbrirReclamacion, request.NumeroSesion.Value, null, null, 0, 0, request.UsuarioRegistra);

            if(abrirReclamacion.Outnum1 != Constantes.RespuestaInfoxprocAbrirReclamacion.ReclamacionAbierta)
                new ResponseDto<ProcesarAutorizacionResponseDto>(null, StatusCodes.Status400BadRequest, DescripcionRespuesta.BadRequest);

            // insertar cobertura
            foreach (var medicamento in request.Medicamentos)
            {
                try
                {                    
                    var insertaCoberturaResult = await _sesionRepositorio.Infoxproc(Constantes.NombreOperacion.InsertarCobertura, request.NumeroSesion.Value, null, null, medicamento.Cantidad, 0);
                }
                catch (Exception)
                {
                    throw new BusinessException($"Error al insertar cobertura");
                }

            }


            var response = new ProcesarAutorizacionResponseDto
            {
                Autorizacion = new AutorizacionDto
                {
                    NumeroAutorizacion = $"{Prefijo.PrefijoPrimeraArs}{94}{abrirReclamacion.Outstr1}",
                    Estado = DescripcionEstatusReclamacion.Abierta,
                    MontoAfiliado = montoAseguradoSum,
                    MontoArs = montoArsSum,
                    MontoReclamado = request.Medicamentos.Select(x => new { Total = x.Cantidad.Value * x.Precio.Value }).Sum(x => x.Total)
                },
                Medicamentos = _mapper.Map<List<MedicamentoResultDto>>(request.Medicamentos)
            };
            return new ResponseDto<ProcesarAutorizacionResponseDto>(response, StatusCodes.Status200OK, DescripcionRespuesta.OK);
        }
    }
}
