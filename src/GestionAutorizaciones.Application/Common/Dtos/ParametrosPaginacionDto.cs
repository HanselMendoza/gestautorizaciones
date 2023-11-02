namespace GestionAutorizaciones.Application.Common.Dtos
{
    public class ParametrosPaginacionDto
    {
        private int pagina { get; set; } = 1;
        private int tamanoPagina { get; set; } = 50;

        private readonly int cantidadMaxRegistro = 100;
        private readonly int cantidadMinPagina = 1;


        public int TamanoPagina
        {
            get => tamanoPagina;
            set
            {
                tamanoPagina = (value > cantidadMaxRegistro) ? cantidadMaxRegistro 
                    : (value < cantidadMinPagina) ? tamanoPagina : value;
            }
        }

        public int Pagina
        {
            get => pagina;
            set
            {
                pagina = (value < cantidadMinPagina) ? cantidadMinPagina : value;
            }
        }
    }
}
