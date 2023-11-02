using GestionAutorizaciones.API.Middlewares;
using Microsoft.AspNetCore.Builder;

namespace GestionAutorizaciones.API.Extensions
{
    public static class AppExtensions
    {
        public static void UseErrorHandlingMiddleware(this IApplicationBuilder app)
        {
            app.UseMiddleware<ErrorHandlerMiddleware>();
        }
    }
}
