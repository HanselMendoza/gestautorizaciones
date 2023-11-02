using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using GestionAutorizaciones.Domain.Entities;

namespace GestionAutorizaciones.Application.Prestadores.Common
{
    public interface IPrestadorRepositorio
    {
        Task<Prestador> ObtenerInfoPss(string tipoPss, long codigoPss);
        Task<SalidaEstandar> ValidarPrestadorEsPaquete(long codigoPss, long cin);
        Task<SalidaEstandar> ValidarPrestadorOfreceTipoCobertra(string tipoPss, long codigoPss, long tipoCobertura);
        Task<SalidaEstandar> ValidarPrestadorOfreceServicio(string tipoPss, long codigoPss, long numeroAsegurado, int secuenciaDependiente);
        Task<IEnumerable<ReclamacionPss>> ObtenerReclamacionesPss(string tipoPss, long codigoPss, DateTime fechaInicio,
            DateTime fechaFin, int? ramo, long? secuencial, string usuarioIngreso, long? numeroPlastico, int? compania);
        Task<TipoPrestador> ObtenerTipoPrestador(long codigoPss, long pin);
        Task<SalidaEstandar> ConfirmarReclamacion(int ano, int compania, int ramo, long secuencial, long codigoPss);
    }
}
