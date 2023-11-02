
namespace GestionAutorizaciones.Application.Common.Utils
{
    public static class Constantes
    {
        public static class NombreOperacion
        {
            public const string AbrirSesion = "OPENSESSION";
            public const string ValidarPin = "VALIDATEPIN";
            public const string ValidarAsegurado = "VALIDATEASEGURADO";
            public const string ValidarCobertura = "VALIDATECOBERTURA";
            public const string ValidarReclamacion = "VALIDATERECLAMACION";
            public const string AbrirReclamacion = "OPENRECLAMACION";
            public const string EliminarReclamacion = "DELETERECLAMACION";
            public const string InsertarCobertura = "INSERTCOBERTURA";
            public const string EliminarCobertura = "DELETECOBERTURA";
            public const string CerrarReclamacion = "CLOSERECLAMACION";
            public const string CerrarSesion = "CLOSESESSION";
            public const string ReactivarsSesion = "REACTIVARSESION";
        }

        public static class CodigoRespuesta
        {
            public const int OK = 0;
		}

		public static class Respuestas
		{
			public static (int Codigo, string Descripcion) OK { get; } = (0, "OK");
			public static (int Codigo, string Descripcion) NotFound { get; } = (404, "Datos no encontrados");
			public static (int Codigo, string Descripcion) BadRequest { get; } = (400, "Error procesando datos");
			public static (int Codigo, string Descripcion) Error { get; } = (500, "Error interno en el servidor");
		}

		public static class DescripcionRespuesta
        {
            public const string OK = "OK";
            public const string Error = "Error interno en el servidor";
            public const string BadRequest = "Error procesando datos";
            public const string NotFound = "Ruta no encontrada";
            public const string NoContent = "Datos no encontrados";
        }

        public static class DescripcionEstatusSesion
        {
            public const string Abierta = "ABIERTA";
        }

        public static class DescripcionEstatusReclamacion
        {
            public const string Abierta = "ABIERTA";
        }

        public static class TipoDocumento
        {
            public const string Cedula = "C";
            public const string Plastico = "P";
            public const string Carnet = "Carnet";
        }

        public static class EmpresaCodigo
        {
            public const int HumanoSeguros = 30;
            public const int PrimeraArs = 96;
        }

        public static class ReclamacionCodigoEstado
        {
            public const int Anulada = 183;
        }

        public static class EmpresaDescripcion
        {
            public const string HumanoSeguros = "Humano Seguros";
            public const string PrimeraArs = "Primera Ars";
        }

        public static class EstadoReclamacion
        {
            public const string EstadoPreAutorizado = "ESTADO_PRE_AUTORIZADO";
            public const string EstadoAperturado = "ESTADO_APERTURADO";
        }

        public static class Prefijo
        {
            public const string PrefijoHumanoSeguros = "H";
            public const string PrefijoPrimeraArs = "P";
        }

        public static class RespuestaInfoxprocAfiliado
        {
            public const string AseguradoValido = "0";
            public const string PlasticoNoExiste = "1";
             public const string NoServicio = "2";
            public const string PlasticoInvalidado = "4";
            public const string CondicionEspecial = "3";
        }

        public static class RespuestaInfoxprocPin
        {
            public const string PinValido = "0";
            public const string PinNoValido = "1";
            public const string PinNoAsignado = "2";

        }



        public static class RespuestaInfoxprocValidaCobertura
        {
            public const string CoberturaValida = "0";
            public const string CoberturaNoDisponibleParaAsegurado = "2";
            public const string PrestadorNoOfreceCobertura = "3";
        }

        public static class RespuestaInfoxprocValidaPrecertificacion
        {
            public const int PrecertificacionValida = 0;
            public const int PrecertificacionNoValida = 1;
            public const int EstadoInvalido = 2;
            public const int PrecertificacionYaConvertida = 3;
        }

        public static class RespuestaInfoxprocAbrirReclamacion
        {
            public const string ReclamacionAbierta = "0";
            public const string ErrorAbrirReclamacion = "1";
        }

        public static class RespuestaInfoxprocInsertarCobertura
        {
            public const string CoberturaInsertada = "0";
            public const string ErrorInsertarCobertura = "1";
        }

        public static class RespuestaInfoxprocCerrarReclamacion
        {
            public const string ReclamacionCerrada = "0";
        }

        public static class RespuestaInfoxprocCerrarSesion
        {
            public const string SesionCerrada = "0";
        }

        public static class RespuestaInfoxprocValidaReclamacion
        {
            public const string ReclamacionValida = "0";
            public const string ReclamacionNoValida = "1";
        }

        public static class RespuestaInfoxprocEliminarReclamacion
        {
            public const string ReclamacionEliminada = "0";
            public const string ErrorEliminarReclamacion = "1";
        }

        public static class RespuestaInfoxprocEliminarCobertura
        {
            public const string CoberturaEliminada = "0";
        }

        public static class CodigoErrorConciliacion
        {
            public const int PlasticoNoCoincide = 1;
            public const int MontosNoCoinciden = 2;
            public const int AutorizacionNoExiste = 3;
            public const int EstadosNoCoinciden = 5;
        }


        public static class MensajeErrorConciliacion
        {
            public const string PlasticoNoCoincide = "Número de plástico no coincide";
            public const string MontosNoCoinciden = "Montos no coinciden";
            public const string AutorizacionNoExiste = "Autorización no existe en CORE";
            public const string EstadosNoCoinciden = "Estados no coinciden";
        }

        public static class MensajeInfoxproc
        {
            public const string PlasticoNoExiste = "El plastico consultado no existe";
            public const string PlanNoVigente = "El asegurado no está vigente en este plan";
            public const string PlasticoInvalidado = "El plastico consultado ha sido invalidado. Llamar al CAC";
            public const string PrestadorNoPuedeOfrecerServicio = "PSS no puede prestar servicio a este asegurado";
            public const string CondicionEspecial = "Condición especial. Llamar al CAC para autorizar";
            public const string PinNoValido = "PIN no válido";
            public const string PinNoAsignado = "No tiene PIN asignado";
            public const string CoberturaNoDisponibleParaAsegurado = "El asegurado no tiene disponible esta cobertura";
            public const string PrestadorNoOfreceCobertura = "El prestador no puede ofrecer esta cobertura";
            public const string ErrorAbrirReclamacion = "Error al crear la reclamación";
            public const string ErrorInsertarCobertura = "Error al insertar el procedimiento";
            public const string CoberturaNoAplicaTipoServicio = "La cobertura no aplica para el tipo de servicio";
            public const string ErrorCerrarReclamacion = "Error al cerrar la reclamación";
            public const string ErrorCerrarSesion = "Error al cerrar la sesión";
            public const string ErrorValidarReclamacion = "La reclamación no existe o tiene en un estado inválido";
            public const string ErrorEliminarReclamacion = "No se pudo borrar la reclamación";
            public const string ErrorEliminarCobertura = "No se pudo borrar la cobertura";
            public const string PrecertificacionNoValida = "Código de pre-certificación no es válido (1)";
            public const string EstadoInvalido = "La pre-certificación tiene en un estado inválido (2)";
            public const string PrecertificacionYaConvertida = "La pre-certificación ya fue convertida (3)";
            public const string ErrorActivarPrecertificacion = "No se pudo activar la pre-certificación";
            public const string ErrorCancelarPrecertificacion = "No se pudo cancelar la pre-certificación";
            public const string PrecertificacionCancelada = "Precertificación cancelada";
        }

        public static class ParametrosFijos
        {
            public const string CodigoMetodoAutenticacion = "2";
            public const int Porcentaje = 99;
            public const string Referencia = "ref";
            public const int Estado = 1;
            public const string UsuarioWs = "AUTORIZACIONES";
            public const int Frecuencia = 1;
        }

    }
}
