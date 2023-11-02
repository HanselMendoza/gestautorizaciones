using System;
using System.Collections.Generic;
using System.Text;

namespace GestionAutorizaciones.Domain.Entities
{
    public class ReclamacionFarmaCard
    {
        public int TipoCobertura { get; set; }
        public int Cobertura { get; set; }
        public string Reclamante { get; set; }
        public int TipoServicio { get; set; }
    }
}
