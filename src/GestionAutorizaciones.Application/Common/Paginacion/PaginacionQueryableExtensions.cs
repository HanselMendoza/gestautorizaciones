using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace GestionAutorizaciones.Application.Common.Paginacion
{
	public static class PaginacionQueryableExtensions
	{
		public static IQueryable<T> Paginar<T>(this IQueryable<T> queryable, int pagina, int tamanoPagina)
		{
			var result = queryable.Skip((pagina - 1) * tamanoPagina).
				Take(tamanoPagina);

			return result;
		}

		public static async Task<(List<TDestination> Items, int TotalPages, int Count)> PaginacionAsync<TDestination>(this IQueryable<TDestination> queryable, int pagina, int tamanoPagina,
			CancellationToken cancellationToken = default) where TDestination : class
		{
			var source = queryable.AsNoTracking();
			var count = await source.CountAsync(cancellationToken);

			var totalPages = (int)Math.Ceiling(count / (double)tamanoPagina);

			var items = await source
				.Skip((pagina - 1) * tamanoPagina)
				.Take(tamanoPagina)
				.ToListAsync(cancellationToken);

			return (items, totalPages, count);
		}
	}
}
