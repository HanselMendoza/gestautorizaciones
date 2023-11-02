
using System.Collections.Generic;
using System.Threading.Tasks;
using GestionAutorizaciones.Domain.Entities;

namespace GestionAutorizaciones.Application.Precertificaciones.Common
{
    public interface IPrecertificacionRepositorio
    {
        Task<ActivacionPrecertificacion> ActivarPrecertificacion(long numeroSesion, long numeroPrecertificacion, string usuarioRegistra);
        Task<IEnumerable<Precertificacion>> ObtenerDatosPrecertificacion(string tipoPss, long codigoPss,
            int compania, long numeroPrecertificacion);
        Task<ValidacionPrecertificacion> ValidarPrecertificacion(string tipoPss, long? codigoPss,
            int? compania, long? numeroPrecertificacion);
        Task<CancelaPrecertificacion> CancelarPrecertificacion(string tipoPss, long? codigoPss, int? compania,
            long? numeroPrecertificacion);
    }
}

