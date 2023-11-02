using System;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;

namespace GestionAutorizaciones.Application.Common.Dtos
{
    public class RespuestaDto
    {
        public RespuestaDto()
        {
            
        }
        private RespuestaDto(int codigo, string mensaje)
        {
            Codigo = codigo;
            Mensaje = mensaje;
            Fecha = DateTime.Now;
        }

        public int Codigo { get; set; }
        public string Mensaje { get; set; }
        public DateTime Fecha { get; set; }
        public static RespuestaDto Ok() => new(Respuestas.OK.Codigo, Respuestas.OK.Descripcion);
		public static RespuestaDto NotFound() => new(Respuestas.NotFound.Codigo, Respuestas.NotFound.Descripcion);
		public static RespuestaDto BadRequest() => new(Respuestas.BadRequest.Codigo, Respuestas.BadRequest.Descripcion);
	}

}
