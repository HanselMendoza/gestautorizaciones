using GestionAutorizaciones.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Text;

namespace GestionAutorizaciones.Application.Common.Options
{
    public class ParametrosConfig
    {
        public string CodigoMetodoAutenticacion { get; set; }
        public int Porcentaje { get; set; }
        public string Referencia { get; set; }
        public int Estado { get; set; }
        public string UsuarioWs { get; set; }
        public ServicioTipoCobertura ServicioConsulta { get; set; }
        public ServicioTipoCobertura ServicioLaboratorio { get; set; }
        public ServicioTipoCobertura ServicioRadiografia { get; set; }
        public ServicioTipoCobertura ServicioEmergencia { get; set; }
        public ServicioTipoCobertura ServicioOdontologia { get; set; }
        public ServicioTipoCobertura ServicioProcedimientos { get; set; }

    }

}
