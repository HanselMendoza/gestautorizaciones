using GestionAutorizaciones.Application.Autorizaciones.Common;
using GestionAutorizaciones.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Text;

namespace GestionAutorizaciones.Infraestructure.Repositories
{
    public class CoberturaSaludRepositorio: GenericRepository<CoberturaSalud>, ICoberturaSaludRepositorio
    {
        public CoberturaSaludRepositorio(ApplicationDbContext dbContext): base(dbContext)
        {
            
        }
    }
}
