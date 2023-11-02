using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading.Tasks;

namespace GestionAutorizaciones.Application.Common.Interfaces
{
    public interface IGenericRepository<TEntity> where TEntity : class
    {
        IEnumerable<TEntity> Get(Expression<Func<TEntity, bool>> filter = null,
            Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>> orderBy = null,
            string includeProperties = "", int? take = null, int? skip = null);
        Task<bool> ExistsAsync(Expression<Func<TEntity, bool>> filter);
        Task<TEntity> GetByKey(params object[] id);
        Task Insert(TEntity entity);
        Task InsertMany(IList<TEntity> entities);
        Task Delete(params object[] keys);
        void Delete(TEntity entityToDelete);
        void DeleteMany(IList<TEntity> entitiesToDelete);
        void Update(TEntity entityToUpdate);
        IQueryable<TEntity> FromSqlRaw(string sql, params object[] parameters);
    }
}
