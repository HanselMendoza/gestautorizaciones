namespace GestionAutorizaciones.Domain.Entities
{
    public class InfoSesion
    {
        public int? Estatus { get; set; }
        public string DescripcionEstatus { get; set; }
        public string EsSoloPbs { get; set; }
        public string EsPssPaquete { get; set; }
        public string TieneExcesoPorGrupo { get; set; }
        public string TipoPss { get; set; }
        public string CodigoPss { get; set; }
        public string CodigoAsegurado { get; set; }
        public string SecuenciaDependiente { get; set; }
    }
}

