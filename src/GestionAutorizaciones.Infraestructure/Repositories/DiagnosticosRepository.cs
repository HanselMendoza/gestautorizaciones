using GestionAutorizaciones.Application.Common.Paginacion;
using GestionAutorizaciones.Application.Diagnosticos.Common;
using GestionAutorizaciones.Domain.Entities;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace GestionAutorizaciones.Infraestructure.Repositories
{
	public class DiagnosticosRepository : IDiagnosticoRepository
	{
		private readonly ApplicationDbContext _context;
		private readonly ILogger _logger;
		public DiagnosticosRepository(ApplicationDbContext context, ILogger<DiagnosticosRepository> logger)
		{
			_context = context;
			_logger = logger;
		}
		public async Task<(ICollection<Diagnostico> diagnosticos, int totalPaginas, int totalRegistros)> ObtenerDiagnosticos(string buscar, int pagina, int tamanioPagina, CancellationToken cancellation = default)
		{
			var (diagnosticos, totalPaginas, totalRegistros) = await _context.Diagnosticos
			.Where(x => x.Descripcion.ToLower().Contains(buscar.ToLower()))
			.OrderBy(x => x.Descripcion)
			.PaginacionAsync(pagina, tamanioPagina, cancellation);

			return (diagnosticos, totalPaginas, totalRegistros);
		}
	}
}
