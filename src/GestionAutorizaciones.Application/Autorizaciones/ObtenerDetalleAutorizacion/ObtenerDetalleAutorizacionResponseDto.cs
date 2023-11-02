using System;
using System.Collections.Generic;
using GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado;

namespace GestionAutorizaciones.Application.Autorizaciones.ObtenerDetalleAutorizacion
{
    public class ObtenerDetalleAutorizacionResponseDto
    {
        public ReclamacionDTO Reclamacion { get; set; }
        public int? Compania { get; set; }
        public int? Ramo { get; set; }
        public long? Secuencial { get; set; }
        public DateTime? Fecha { get; set; }
        public long? CodigoEstado { get; set; }
        public string NombreEstado { get; set; }
        public long? CodigoPss { get; set; }
        public string NombrePss { get; set; }
        public string TipoPss { get; set; }
        public string UsuarioIngreso { get; set; }
        public decimal? TotalReclamado { get; set; }
        public decimal? TotalARS { get; set; }
        public decimal? TotalAfiliado { get; set; }
        public long? CodigoServicio { get; set; }
        public AfiliadoDTO Afiliado { get; set; }
        public List<ProcedimientoDTO> Procedimientos { get; set; }
    }

    public class ReclamacionDTO
    {
        public CompaniaInfo Compania { get; set; }
        public string NumeroAutorizacion { get; set; }
    }

    public class CompaniaInfo
    {
        public int Codigo { get; set; }
        public string Nombre { get; set; }
    }


    public class ProcedimientoDTO
    {
        public long? Codigo { get; set; }
        public string Nombre { get; set; }
        public long? Frecuencia { get; set; }
        public decimal? MontoReclamado { get; set; }
        public decimal? MontoARS { get; set; }
        public decimal? MontoAfiliado { get; set; }
    }
}
