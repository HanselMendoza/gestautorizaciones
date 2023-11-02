using System;

namespace GestionAutorizaciones.Application.Common.Dtos
{
    public class ResponseDto
    {
        public RespuestaDto respuesta { get; set; }
    }


    public class ResponseDto<T> : ResponseDto
    {
        public ResponseDto()
        {

        }

        public ResponseDto(T data, int codigo, string mensaje = null)
        {
            respuesta = new RespuestaDto
            {
                Codigo = codigo,
                Mensaje = mensaje,
                Fecha = DateTime.Now
            };

            Data = data;

        }
        public T Data { get; set; }

    }
}
