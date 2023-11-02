using System;
using System.Collections.Generic;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using GestionAutorizaciones.API.Utils;

namespace GestionAutorizaciones.API.Options
{
    public class AddCustomHeadersSwagger : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            if (operation.Parameters == null)
                operation.Parameters = new List<OpenApiParameter>();

            operation.Parameters.Add(new OpenApiParameter
            {
                Name = HeaderConstants.ClientId,
                In = ParameterLocation.Header,
                Description = nameof(HeaderConstants.ClientId),
                Required = true
            });

            operation.Parameters.Add(new OpenApiParameter
            {
                Name = HeaderConstants.ApiKey,
                In = ParameterLocation.Header,
                Description = nameof(HeaderConstants.ApiKey),
                Required = true
            });
        }
    }
}