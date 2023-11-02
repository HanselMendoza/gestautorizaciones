using System;
using System.Collections.Generic;

namespace GestionAutorizaciones.Application.Autorizaciones.CompararAutorizacion
{
    public class CompararAutorizacionResponseDto
    {
        public List<ErrorCompararAutorizacion> Errores { get; set; }
    }

    public class ErrorCompararAutorizacion
    {
        public ErrorComparar Error { get; set; }
        public int? Ano { get; set; }
        public int? Compania { get; set; }
        public int? Ramo { get; set; }
        public long? Secuencial { get; set; }
        public DateTime? Fecha { get; set; }
        public int? Estado { get; set; }
        public long? NumeroPlastico { get; set; }
        public decimal? MontoReclamado { get; set; }
        public decimal? MontoARS { get; set; }
        public decimal? MontoAsegurado { get; set; }
    }

    public class ErrorComparar
    {
        public int? Codigo { get; set; }
        public string Descripcion { get; set; }
    }
}
