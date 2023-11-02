
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using GestionAutorizaciones.Application;
using GestionAutorizaciones.Infraestructure;
using Newtonsoft.Json;
using Microsoft.AspNetCore.Http;
using GestionAutorizaciones.Application.Common.Options;
using GestionAutorizaciones.Application.Common.Exceptions;
using GestionAutorizaciones.API.Extensions;
using GestionAutorizaciones.API.Options;
using Microsoft.AspNetCore.Mvc.ApiExplorer;
using GestionAutorizaciones.API.Middlewares;

namespace GestionAutorizaciones.API
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.Configure<ParametrosConfig>(Configuration.GetSection("Parametros"));

            services.AddInfraestructure();
            services.AddApplication();
            services.AddControllers(o =>
            {
                o.UseGeneralRoutePrefix(Utils.Routes.GlobalPrefix);
            });

            services.AddRouting(o => o.LowercaseUrls = true);
            services.AgregarSwagger();

            //Versionamiento
            services.AgregarVersionamiento();

        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IApiVersionDescriptionProvider provider)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseExceptionHandler(a => a.Run(async context =>
            {
                var exception = context.Features
                    .Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerPathFeature>()
                    .Error;

                if (exception is FluentValidation.ValidationException)
                    context.Response.StatusCode = StatusCodes.Status400BadRequest;

                if (exception is BusinessException)
                    context.Response.StatusCode = StatusCodes.Status422UnprocessableEntity;

                var result = JsonConvert.SerializeObject(new { error = exception.Message });

                context.Response.ContentType = "application/json";
                await context.Response.WriteAsync(result);
            }));

            if (!env.IsProduction())
            {
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.RoutePrefix = string.Empty;

                    foreach (var description in provider.ApiVersionDescriptions)
                    {
                        c.SwaggerEndpoint($"/swagger/{description.GroupName}/swagger.json", description.GroupName.ToUpperInvariant());
                    }
                });
            }

            app.UseHttpsRedirection();

            app.UseRouting();
            app.UseMiddleware<RequestResponseLoggingMiddleware>();
            app.UseErrorHandlingMiddleware();

            app.UseAuthorization();
            app.UseMiddleware<AuthenticationMiddleware>();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
