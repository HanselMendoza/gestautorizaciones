using System;
using Microsoft.Extensions.DependencyInjection;
using GestionAutorizaciones.Infraestructure.Repositories;
using Microsoft.EntityFrameworkCore;
using GestionAutorizaciones.Infraestructure.Services;
using GestionAutorizaciones.Application.Common.Interfaces;
using GestionAutorizaciones.Application.Procedimientos.Common;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Application.Asegurado.Common;
using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Precertificaciones.Common;
using GestionAutorizaciones.Application.Auth.Common;
using GestionAutorizaciones.Application.Autorizaciones.Common;
using GestionAutorizaciones.Application.Diagnosticos.Common;

namespace GestionAutorizaciones.Infraestructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfraestructure(this IServiceCollection services)
        {
            //Repositorios.
            services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
            services.AddScoped(typeof(ISesionRepositorio), typeof(SesionRepositorio));
            services.AddScoped(typeof(IAutorizacionRepositorio), typeof(AutorizacionRepositorio));
            services.AddScoped(typeof(IPrestadorRepositorio), typeof(PrestadorRepositorio));
            services.AddScoped(typeof(IAseguradoRepositorio), typeof(AseguradoRepositorio));
            services.AddScoped(typeof(IProcedimientoRepositorio), typeof(ProcedimientoRepositorio));
            services.AddScoped(typeof(IPrecertificacionRepositorio), typeof(PrecertificacionRepositorio));
            services.AddScoped(typeof(ICoberturaSaludRepositorio), typeof(CoberturaSaludRepositorio));
			services.AddScoped(typeof(IDiagnosticoRepository), typeof(DiagnosticosRepository));

			services.AddDbContext<ApplicationDbContext>(options =>
            {
                options.UseOracle(Environment.GetEnvironmentVariable("CONNECTION_STRING"), b => b.UseOracleSQLCompatibility("11"));
            });

            //Services.
            services.AddTransient<IAuthService, AuthService>();

            return services;
        }
    }
}