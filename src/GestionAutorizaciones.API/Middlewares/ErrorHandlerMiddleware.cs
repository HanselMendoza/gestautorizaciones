using System;
using System.Collections.Generic;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using GestionAutorizaciones.Application.Common.Dtos;
using GestionAutorizaciones.Application.Common.Exceptions;
using GestionAutorizaciones.Application.Exceptions;
using GestionAutorizaciones.API.Exceptions;

namespace GestionAutorizaciones.API.Middlewares
{
    public class ErrorHandlerMiddleware
    {
        private readonly RequestDelegate _next;

        public ErrorHandlerMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task Invoke(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.StackTrace);
                var respuesta = context.Response;
                respuesta.ContentType = "application/json";
                var codigoInternoError = 1;
                var responseModel = new ResponseDto<string>()
                {
                    respuesta = new RespuestaDto
                    {
                        Codigo = codigoInternoError,
                        Mensaje = ex?.Message
                    }
                };
                switch (ex)
                {
                    case ApiException e:
                        respuesta.StatusCode = (int)HttpStatusCode.BadRequest;
                        break;

                    case ValidationException e:
                        respuesta.StatusCode = (int)HttpStatusCode.BadRequest;
                        break;

                    case KeyNotFoundException e:
                        respuesta.StatusCode = (int)HttpStatusCode.NotFound;
                        break;
                    
                    case UnauthorizedException e:
                        respuesta.StatusCode = (int) HttpStatusCode.Unauthorized;
                        break;
                    
                    case NoTienePermisoException e:
                        respuesta.StatusCode = (int) HttpStatusCode.Forbidden;
                        break;
                    
                    default:
                        respuesta.StatusCode = (int)HttpStatusCode.InternalServerError;
                        break;

                }

                var result = JsonSerializer.Serialize(responseModel, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });

                await respuesta.WriteAsync(result);
            }
        }
    }
}
