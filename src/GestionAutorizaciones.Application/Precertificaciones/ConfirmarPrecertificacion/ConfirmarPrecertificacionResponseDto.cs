namespace GestionAutorizaciones.Application.Precertificaciones.ConfirmarPrecertificacion
{
    public class ConfirmarPrecertificacionResponseDto
    {
        public long NumeroSesion { get; set; }
        public string NumeroAutorizacion { get; set; }
        public string TipoAutorizacion { get; set; }
        public string DescripcionTipoAutorizacion  => Application.Common.Utils.Funciones.ObtenerDescripcionTipoAutorizacion(TipoAutorizacion);
    }
}