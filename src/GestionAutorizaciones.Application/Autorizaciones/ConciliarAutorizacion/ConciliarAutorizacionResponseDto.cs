using System;
using System.Collections.Generic;

namespace GestionAutorizaciones.Application.Autorizaciones.ConciliarAutorizacion
{
    public class ConciliarAutorizacionResponseDto
    {
        public List<ErrorDetalle> Errores { get; set; }
    }
    public class ErrorDetalle
    {
        public Error Error { get; set; }
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

    public class Error
    {
        public int? Codigo { get; set; }
        public string Descripcion { get; set; }
    }
}
