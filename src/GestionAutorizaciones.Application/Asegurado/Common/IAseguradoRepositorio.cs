using System;
using GestionAutorizaciones.Domain.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;


namespace GestionAutorizaciones.Application.Asegurado.Common
{
    public interface IAseguradoRepositorio
    {
        Task<SalidaEstandar> ValidarAfiliadoAplicaPBS(long numeroPlastico, DateTime fecha);
        Task<Telefono> ObtenerTelefono(long numeroPlastico);
        Task<OrigenPlastico> ObtenerOrigenPlastico(long numeroPlastico);
        Task<IEnumerable<Nucleo>> ObtenerNucleos(long numeroPlastico);
        Task<Afiliado> ObtenerAfiliado(string tipoId, string identificacion, int compania);
        Task<SalidaEstandar> ValidarAfiliadoAgotoConsultasAmbulatorias(long numeroPlastico, string tipoCanal, DateTime fecha);
        Task<SalidaEstandar> ValidarAfiliadoTieneConsultasPrevias(long numeroPlastico, string tipoCanal, DateTime fechaServicio, long centro, string tipoReclamante);
        Task<SalidaEstandar> ValidarAfiliadoSoloTieneEmergencia(long numeroPlastico);
    }
}
