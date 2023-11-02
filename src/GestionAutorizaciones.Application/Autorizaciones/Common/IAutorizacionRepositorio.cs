using GestionAutorizaciones.Domain.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace GestionAutorizaciones.Application.Autorizaciones.Common
{
    public interface IAutorizacionRepositorio
    {
        Task<IEnumerable<Reclamacion>> ObtenerInformacionReclamaciones(int? ano, int? compania,
           int? ramo, long? secuencial, long? codigoPss);

        Task<(decimal montoArs, decimal montoAsegurado)> ValidarCoberturaMedicina(long numeroSesion, string codigoSimon, string descripcionMedicamento, int cantidad, decimal precio);

    }
}
