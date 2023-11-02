using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidos;
using MediatR;
using System;
using System.Collections.Generic;
using System.Text;

namespace GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidosNoServicio
{
    public class ObtenerProcedimientosPermitidosNoServicioQuery : ParametrosPaginacionDto, IRequest<PaginacionDto<ObtenerProcedimientosPermitidosResponseDto>>
    {
        public string TipoPss { get; set; }
        public long CodigoPss { get; set; }
        public long? Cobertura { get; set; }
        public string NombreCobertura { get; set; }
        public long? Servicio { get; set; }
    }
}
