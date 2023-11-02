using System.Threading.Tasks;
using System.Collections.Generic;
using GestionAutorizaciones.Domain.Entities;

namespace GestionAutorizaciones.Application.Procedimientos.Common
{
    public interface IProcedimientoRepositorio
    {
        Task<SalidaEstandar> ValidarPasaReglasCobertura(long numeroSesion, long tipoServicio, long cobertura);
        Task<SalidaEstandar> ValidarCoberturaLaboratorio(long cobertura);
        Task<SalidaEstandar> ValidarCoberturaConsulta(long cobertura);
        Task<IEnumerable<Procedimiento>> ObtenerProcedimientos(string tipoPss, long todigoPss, long? servicio);
        Task<IEnumerable<ProcedimientoNoServicio>> ObtenerProcedimientosNoServicio(string tipoPss, long codigoPss, long? servicio);
        Task<SalidaEstandar> ValidarEstudioEspecial(long servicio, long cobertura, string tipoCanal);
    }
}
