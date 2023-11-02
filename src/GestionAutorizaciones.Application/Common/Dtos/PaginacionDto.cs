using System;

namespace GestionAutorizaciones.Application.Common.Dtos
{
	public class PaginacionDto<T> : ResponseDto<T>
	{

		public PaginacionDto(T data, int pagina, int tamanoPagina, int totalPaginas, int totalRegistros, string mensaje, int codigo)
		{
			respuesta = new RespuestaDto
			{
				Mensaje = mensaje,
				Fecha = DateTime.Now,
				Codigo = codigo
			};

			paginacion = new Paginacion
			{
				Pagina = pagina,
				TamanoPagina = tamanoPagina,
				TotalPaginas = totalPaginas,
				TotalRegistros = totalRegistros
			};

			this.Data = data;

		}

		private PaginacionDto(T data, int pagina, int tamanoPagina, int totalPaginas, int totalRegistros)
		{
			respuesta = RespuestaDto.Ok();
			paginacion = new Paginacion
			{
				Pagina = pagina,
				TamanoPagina = tamanoPagina,
				TotalPaginas = totalPaginas,
				TotalRegistros = totalRegistros
			};

			this.Data = data;
		}


		public static PaginacionDto<T> OK(T data, int pagina, int tamanoPagina, int totalPaginas, int totalRegistros)
			=> new(data, pagina, tamanoPagina, totalPaginas, totalRegistros);

		public Paginacion paginacion { get; set; }
		public class Paginacion
		{
			public int Pagina { get; set; }
			public int TamanoPagina { get; set; }
			public int TotalPaginas { get; set; }
			public int TotalRegistros { get; set; }
		}
	}


}

