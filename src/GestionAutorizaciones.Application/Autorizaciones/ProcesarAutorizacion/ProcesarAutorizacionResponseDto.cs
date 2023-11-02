using System;
using System.Collections.Generic;
using System.Text;

namespace GestionAutorizaciones.Application.Autorizaciones.ProcesarAutorizacion
{
    public class ProcesarAutorizacionResponseDto
    {
        public AutorizacionDto Autorizacion { get; set; }
        public List<MedicamentoResultDto> Medicamentos { get; set; }
    }

    public class AutorizacionDto
    {
        public string NumeroAutorizacion { get; set; }
        public string Estado { get; set; }
        public decimal MontoReclamado { get; set; }
        public decimal MontoArs { get; set; }
        public decimal MontoAfiliado { get; set; }

    }

    public class MedicamentoResultDto
    {
        public string CodigoSimon { get; set; }
        public string Descripcion { get; set;}
        public string TipoMedicamento { get; set; }
        public int Cantidad { get; set; }
        public decimal Precio { get; set; }
        public decimal MontoCubierto { get; set; }
        public int CodigoError { get; set; }
        public string DescripcionError { get; set; }

    }
}
