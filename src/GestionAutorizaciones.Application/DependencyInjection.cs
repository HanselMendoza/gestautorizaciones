
using Microsoft.Extensions.DependencyInjection;
using GestionAutorizaciones.Application.Common.Behaviors;
using FluentValidation;
using MediatR;
using System.Reflection;

namespace GestionAutorizaciones.Application
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddApplication(this IServiceCollection services)
        {
            services.AddAutoMapper(Assembly.GetExecutingAssembly());
            services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
			services.AddMediatR(cfg =>
			{
				cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly());
				cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
			});


			return services;
        }
    }
}