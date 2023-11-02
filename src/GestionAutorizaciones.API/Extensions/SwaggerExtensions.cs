using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.OpenApi.Models;
using GestionAutorizaciones.API.Utils;
using GestionAutorizaciones.API.Options;

namespace GestionAutorizaciones.API.Extensions
{
    public static class SwaggerExtensions
    {
        public static void AgregarSwagger(this IServiceCollection services)
        {
            services.AddSwaggerGen(c =>
            {
                c.EnableAnnotations();
                c.OperationFilter<AddCustomHeadersSwagger>();

                c.AddSecurityDefinition(HeaderConstants.AuthorizationType, new OpenApiSecurityScheme
                {
                    Description = string.Format("API utiliza {0} token", HeaderConstants.AuthorizationType),
                    Name = nameof(HeaderConstants.Authorization),
                    In = ParameterLocation.Header,
                    Type = SecuritySchemeType.ApiKey,
                    Scheme = HeaderConstants.AuthorizationType
                });

                c.AddSecurityRequirement(new OpenApiSecurityRequirement()
                {
                    {
                    new OpenApiSecurityScheme
                    {
                        Reference=new OpenApiReference
                        {
                            Type = ReferenceType.SecurityScheme,
                            Id = HeaderConstants.AuthorizationType
                        },
                        Scheme= HeaderConstants.AuthorizationType,
                        Name = HeaderConstants.AuthorizationType,
                        In = ParameterLocation.Header
                    },
                    new System.Collections.Generic.List<string>()
                    }
                });
            });

            services.ConfigureOptions<ConfigureSwaggerOptions>();
        }
    }
}