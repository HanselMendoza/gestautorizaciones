using System;
using System.Collections.Generic;
using System.Text;

namespace GestionAutorizaciones.Domain.Entities
{
    public class CoberturaSalud
    {
        public int Codigo { get; set; }
        public string Descripcion { get; set; }
        public string CodigoSimon { get; set; }
        public int Agrupador { get; set; }
    }
}
