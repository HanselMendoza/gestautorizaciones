using GestionAutorizaciones.Domain.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace GestionAutorizaciones.Application.Sesion.Common
{
    public interface ISesionRepositorio
    {
        Task<RespuestaInfoxProc> Infoxproc(string nombreFuncion, long numeroSesion,
            string inString1, string inString2, int? innum1, int? innum2, string usuarioRegistra = null);
        Task<InfoSesion> ObtenerInfoSesion(long numeroSesion);
        Task<SalidaEstandar> ActualizarInfoSession(long numeroSesion, InfoSesion datosSession);

        Task<SolicitudArl> MarcarComoArl(long numeroSesion);
        Task<Domain.Entities.Sesion> ReactivarSesion(int? ano, int? compania,
            int? ramo, long? secuencial);
        Task<List<DetalleReclamacion>> ObtenerDetalleReclamacion(long numeroSesion);
    }
}
