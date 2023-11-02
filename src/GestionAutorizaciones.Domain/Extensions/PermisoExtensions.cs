using GestionAutorizaciones.Domain.Entities.Enums;
using System.Linq;

namespace GestionAutorizaciones.Domain.Extensions
{
    public static class PermisoExtensions
    {

        public static string GetScope(this Permiso enumValue)
        {
            var partesScope = enumValue.GetName().SplitPascalCase(findFirst: true).Select(parte => parte.ToLowerFirstLetter());
            return string.Join(':', partesScope);
        }
    }
}