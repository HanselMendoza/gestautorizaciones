using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace GestionAutorizaciones.Application.Diagnosticos.Common
{
	public interface IDiagnosticoRepository
	{
		Task<(ICollection<Domain.Entities.Diagnostico> diagnosticos, int totalPaginas, int totalRegistros)>
			ObtenerDiagnosticos(string buscar, int pagina, int tamanioPagina, CancellationToken cancellation = default);
	}
}
