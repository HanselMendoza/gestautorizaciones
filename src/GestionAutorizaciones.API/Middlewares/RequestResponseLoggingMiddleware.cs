using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.IO;

namespace GestionAutorizaciones.API.Middlewares
{
    public class RequestResponseLoggingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger _logger;
        private readonly RecyclableMemoryStreamManager _recyclableMemoryStreamManager;

        public RequestResponseLoggingMiddleware(RequestDelegate next, ILoggerFactory loggerFactory)
        {
            _next = next;
            _logger = loggerFactory.CreateLogger<RequestResponseLoggingMiddleware>();
            _recyclableMemoryStreamManager = new RecyclableMemoryStreamManager();
        }

        public async Task Invoke(HttpContext context)
        {
            await LogRequest(context);
            await LogResponse(context);
        }
    
        private async Task LogRequest(HttpContext context)
        {
            context.Request.EnableBuffering();

            string headers = String.Empty;
            foreach (var key in context.Request.Headers.Keys)
            headers += "   >>> " + key + "=" + context.Request.Headers[key] + Environment.NewLine;

            await using var requestStream = _recyclableMemoryStreamManager.GetStream();
            await context.Request.Body.CopyToAsync(requestStream);
            _logger.LogInformation($"******************** HTTP REQUEST ******************** :{Environment.NewLine}" +
                                $"Request TraceID: {context.TraceIdentifier} {Environment.NewLine}" +
                                $"Host: {context.Request.Host} {Environment.NewLine}" +
                                $"Path: {context.Request.Path} {Environment.NewLine}" +
                                $"Method: {context.Request.Method} {Environment.NewLine}" +
                                $"QueryString: {context.Request.QueryString} {Environment.NewLine}" +
                                $"Request Body: {ReadStreamInChunks(requestStream)} {Environment.NewLine}" +
                                $"Headers: {headers}");
                                
            context.Request.Body.Position = 0;
        }

        private static string ReadStreamInChunks(Stream stream)
        {
            const int readChunkBufferLength = 4096;

            stream.Seek(0, SeekOrigin.Begin);

            using var textWriter = new StringWriter();
            using var reader = new StreamReader(stream);

            var readChunk = new char[readChunkBufferLength];
            int readChunkLength;

            do
            {
                readChunkLength = reader.ReadBlock(readChunk, 
                                                0, 
                                                readChunkBufferLength);
                textWriter.Write(readChunk, 0, readChunkLength);
            } while (readChunkLength > 0);

            return textWriter.ToString();
        }
        private async Task LogResponse(HttpContext context)
        {
            var originalBodyStream = context.Response.Body;

            await using var responseBody = _recyclableMemoryStreamManager.GetStream();
            context.Response.Body = responseBody;

            await _next(context);

            context.Response.Body.Seek(0, SeekOrigin.Begin);
            var text = await new StreamReader(context.Response.Body).ReadToEndAsync();
            context.Response.Body.Seek(0, SeekOrigin.Begin);

            _logger.LogInformation($"******************** HTTP RESPONSE ******************** {Environment.NewLine}" +
                                $"Request TraceID: {context.TraceIdentifier} {Environment.NewLine}" +
                                $"Host: {context.Request.Host} {Environment.NewLine}" +
                                $"Path: {context.Request.Path} {Environment.NewLine}" +
                                $"Method: {context.Request.Method} {Environment.NewLine}" +
                                $"QueryString: {context.Request.QueryString} {Environment.NewLine}" +
                                $"Status code: {context.Response.StatusCode} {Environment.NewLine}" +
                                $"Response Body: {text}");
            await responseBody.CopyToAsync(originalBodyStream);
        }
    }
}