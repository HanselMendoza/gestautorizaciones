
using System;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Common.Enums;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;

namespace GestionAutorizaciones.Application.Common.Utils
{
    public static class Funciones
    {

        public static OrigenDto ObtenerOrigenPorParametro(string parametro)
        {

            if (parametro == "B" || parametro == "BB")
            {
                return new OrigenDto
                {
                    Codigo = 1,
                    Abreviatura = "ARS",
                    Descripcion = EmpresaDescripcion.PrimeraArs,
                    Prefijo = "P",
                    Compania = EmpresaCodigo.PrimeraArs
                };

            }

            if (parametro == "V" || parametro == "VV" || parametro == "XV")
            {
                return new OrigenDto
                {
                    Codigo = 2,
                    Abreviatura = "ASE",
                    Descripcion = EmpresaDescripcion.HumanoSeguros,
                    Prefijo = "H",
                    Compania = EmpresaCodigo.HumanoSeguros
                };

            }

            return new OrigenDto
            {
                Codigo = 0,
                Abreviatura = "ND",
                Descripcion = "N/D",
                Prefijo = "",
                Compania = 0
            };

        }

        public static OrigenDto ObtenerOrigenPorRamo(int ramo)
        {

            if (ramo == 94)
            {
                return new OrigenDto
                {
                    Codigo = 1,
                    Abreviatura = "ARS",
                    Descripcion = EmpresaDescripcion.PrimeraArs,
                    Prefijo = "P",
                    Compania = EmpresaCodigo.PrimeraArs
                };

            }

            return new OrigenDto
            {
                Codigo = 2,
                Abreviatura = "ASE",
                Descripcion = EmpresaDescripcion.HumanoSeguros,
                Prefijo = "H",
                Compania = EmpresaCodigo.HumanoSeguros
            };

        }

        public static AutorizacionLegacyDto ObtenerAutorizacionLegacy(string numeroAutorizacion)
        {
            try
            {
                string cleanNumber = numeroAutorizacion.Replace("-", string.Empty);
                var prefijo = cleanNumber.Substring(0, 1);
                var ramo = cleanNumber.Substring(1, 2);
                var secuencial = cleanNumber.Substring(3);
                int compania = (prefijo == Prefijo.PrefijoPrimeraArs) ? (int)Compania.Primera : (int)Compania.Humano;

                return new AutorizacionLegacyDto
                {
                    Compania = compania,
                    Ramo = int.Parse(ramo),
                    Secuencial = long.Parse(secuencial)
                };

            }
            catch (Exception)
            {
                return null;
            }

        }

        public static string ObtenerDescripcionTipoAutorizacion(string tipo)
        {
            if (tipo == "I") return "Ingreso";
            if (tipo == "R") return "Reclamación";
            return default;
        }

    }
}
