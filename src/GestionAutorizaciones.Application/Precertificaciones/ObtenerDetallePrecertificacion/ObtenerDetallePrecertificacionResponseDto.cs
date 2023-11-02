using System;
using System.Collections.Generic;
using GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado;
using GestionAutorizaciones.Application.Autorizaciones.ObtenerDetalleAutorizacion;

namespace GestionAutorizaciones.Application.Precertificaciones.ObtenerDetallePrecertificacion
{
    public class ObtenerDetallePrecertificacionResponseDto
    {
        public PrecertificacionDTO Precertificacion { get; set; }
    }

    public class PrecertificacionDTO
    {
        public CompaniaInfoDto CompaniaInfo { get; set; }
        public long NumeroPrecertificacion { get; set; }
        public int? Compania { get; set; }
        public int? Ramo { get; set; }
        public long? Secuencial { get; set; }
        public DateTime? Fecha { get; set; }
        public long? CodigoEstado { get; set; }
        public string NombreEstado { get; set; }
        public long? CodigoPss { get; set; }
        public string NombrePss { get; set; }
        public string UsuarioIngreso { get; set; }
        public decimal? TotalReclamado { get; set; }
        public decimal? TotalARS { get; set; }
        public decimal? TotalAfiliado { get; set; }
        public AfiliadoDTO Afiliado { get; set; }
        public List<ProcedimientoDTO> Procedimientos { get; set; }

    }

    public class CompaniaInfoDto
    {
        public int? Codigo { get; set; }
        public string Nombre { get; set; }
    }

}
