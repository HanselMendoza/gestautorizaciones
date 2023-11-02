using System;
using System.Collections.Generic;
using System.Text;

namespace GestionAutorizaciones.Domain.Entities
{
    public class ServicioTipoCobertura
    {
        private const int TAMANO_PREFIJO_SERVICIO_TIPO = 4;

        public ServicioTipoCobertura()
        {
        }

        public ServicioTipoCobertura(int servicio, int tipoCobertura, int? cobertura)
        {
            Servicio = servicio;
            TipoCobertura = tipoCobertura;
            Cobertura = cobertura;
        }

        public ServicioTipoCobertura(string tipoServicioCobertura)
        {
            if (tipoServicioCobertura is null || int.Parse(tipoServicioCobertura) <= 0)
                throw new ArgumentNullException(nameof(tipoServicioCobertura));

            if(tipoServicioCobertura.Length >= TAMANO_PREFIJO_SERVICIO_TIPO)
            {
                Servicio = Convert.ToInt32(tipoServicioCobertura.Substring(0, 2));
                TipoCobertura = Convert.ToInt32(tipoServicioCobertura.Substring(2, 2));
            }
            if(tipoServicioCobertura.Length > TAMANO_PREFIJO_SERVICIO_TIPO)
            {
                Cobertura = Convert.ToInt32(tipoServicioCobertura.Substring(4));
            }
        }

        public int Servicio { get; set; }
        public int TipoCobertura { get; set; }
        public int? Cobertura { get; set; }

        public override string ToString()
        {
            var cobertura = Cobertura.HasValue ? Cobertura.Value.ToString("0000000000") : string.Empty;
            return $"{Servicio.ToString("00")}{TipoCobertura.ToString("00")}{cobertura}";
        }
    }
}
