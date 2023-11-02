using System;
using System.Text;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using GestionAutorizaciones.API.Exceptions;
using GestionAutorizaciones.API.Utils;
using GestionAutorizaciones.API.Attributes;
using Microsoft.AspNetCore.Http.Features;
using GestionAutorizaciones.Application.Auth.DTOs;
using AuthenticationAPI.Driver.Models;
using GestionAutorizaciones.Application.Auth.Common;
using Microsoft.Extensions.Logging;

namespace GestionAutorizaciones.API.Middlewares
{
    public class AuthenticationMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IAuthService _authService;
        private readonly ILogger _logger;

        public AuthenticationMiddleware(RequestDelegate next, IAuthService authService, ILogger<AuthenticationMiddleware> logger)
        {
            _next = next;
            _authService = authService;
            _logger = logger;
        }

        public async Task Invoke(HttpContext context)
        {
            var (clientId, apiKey, token) = CheckAndSetHeaders(context);
            ThrowIfEmptyRequiredHeader(context, clientId, apiKey, token);

            if (RequiresUserToken(context) &&  !string.IsNullOrWhiteSpace(token))
            {
                await ValidateAuthToken(clientId, apiKey, token);

                User user = await GetAuthUser(clientId, apiKey, token);
                var usuario = MapToUsuario(user);
                context.Items[nameof(Usuario)] = usuario;
                // context.User = GetPrincipal(usuario, token);
            }

            Client cliente = await GetAuthClient(clientId, apiKey);

            var clienteConfig = GetClienteConfig(cliente, clientId, apiKey);
            context.Items[HttpContextItems.ClienteConfig] = clienteConfig;

            await _next(context);

        }

        private Usuario MapToUsuario(User usuario)
        {
            PerfilUsuario perfil = null;
            MetadataConfig metadataConfig = null;

            if (!(usuario.Profile is null) )
            {
                perfil = new PerfilUsuario 
                { 
                    Name = usuario.Profile.Name,
                    LastName = usuario.Profile.LastName,
                    Birthdate = usuario.Profile.Birthdate,
                    DocumentNumber = usuario.Profile.DocumentNumber,
                    DocumentType = usuario.Profile.DocumentType,
                    Sex = usuario.Profile.Sex
                };
            }

            if (usuario.Metadata != null && usuario.Metadata.Any())
            {
                metadataConfig = new MetadataConfig
                {
                    Id = usuario?.Metadata?.GetString("id"),
                    Role = usuario?.Metadata?.GetString("role")
                };
            }
            
            return new Usuario
            {
                Username = usuario.Username,
                Email = usuario.Email,
                Blocked = usuario.Blocked,
                IsActive = usuario.IsActive,
                IsExternal = usuario.IsExternal,
                IsSuperUser = usuario.IsSuperUser,
                Profile =  perfil,
                Config = metadataConfig
            };
        }

        private async Task<User> GetAuthUser(string clientId, string apiKey, string token)
        {
            var (user, respuesta) = await _authService.GetCurrentUser(clientId, apiKey, token);
            if (!respuesta.Success ?? false) throw new UnauthorizedException($"Error retrieving user {respuesta.Code} - {respuesta.Message}");
            if (user == null) throw new UnauthorizedException($"Ups! user doesn't exists {respuesta.Code} - {respuesta.Message}");
            return user;
        }

        private async Task<Client> GetAuthClient(string clientId, string apiKey)
        {
            var (cliente, respuesta) = await _authService.GetCurrentClient(clientId, apiKey);

            if (!respuesta.Success ?? false) throw new UnauthorizedException($"Error retrieving client {respuesta.Code} - {respuesta.Message}");
            if (cliente == null) throw new UnauthorizedException($"Ups! client is unknown {respuesta.Code} - {respuesta.Message}");
            return cliente;
        }

        private async Task ValidateAuthToken(string clientId, string apiKey, string token)
        {
            var (isValid, message) = await _authService.ValidateToken(clientId, apiKey, token);
            if (!isValid) throw new UnauthorizedException(message);
        }

        private ClaimsPrincipal GetPrincipal(Usuario usuario, string token)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            try
            {            
                var decoded = tokenHandler.ReadJwtToken(token);
                
                if (decoded is null || !decoded.Claims.Any()) return null;
                var claimsDict = decoded.Claims.ToDictionary(k => k.Type, v => v.Value);
                var issuer = claimsDict.GetValueOrDefault("iss");
                var nameId = claimsDict.GetValueOrDefault("nameid");
                var id = claimsDict.GetValueOrDefault("id");
                var role = claimsDict.GetValueOrDefault("role");

                if (usuario.Config is null)
                {
                    usuario.Config = new MetadataConfig
                    {
                        Id = id,
                        Role = role
                    };
                }

                var claims = new List<Claim> {
                    new Claim(ClaimTypes.NameIdentifier, nameId, issuer),
                    new Claim(ClaimTypes.Sid, id),
                    new Claim(ClaimTypes.Role,role, issuer ),
                    new Claim(ClaimTypes.Expiration,claimsDict.GetValueOrDefault("exp"), issuer),
                    new Claim(ClaimTypes.Authentication,"true",ClaimValueTypes.Boolean,issuer),
                    new Claim(ClaimTypes.Email, usuario.Email)
                };

                if (usuario.Profile is null) {
                    claims.Add(new Claim(ClaimTypes.Name, usuario.Username, issuer));
                } else
                {
                    claims.AddRange(new List<Claim> {
                        new Claim(ClaimTypes.Name,usuario.Profile.Name ?? ""),
                        new Claim(ClaimTypes.GivenName, usuario.Profile.LastName ?? ""),
                        new Claim(ClaimTypes.DateOfBirth, usuario.Profile.Birthdate?.ToShortDateString()),
                        new Claim(ClaimTypes.Gender, usuario.Profile.Sex ?? ""),
                        new Claim(nameof(PerfilUsuario.DocumentType), usuario.Profile.DocumentType ?? ""),
                        new Claim(nameof(PerfilUsuario.DocumentNumber), usuario.Profile.DocumentNumber ?? ""),
                    });
                }

                var identity = new ClaimsIdentity(claims);
                var principal = new ClaimsPrincipal(identity);
                return principal;
            }
            catch (Exception ex)
            {
                _logger.LogError("Ocurrió un error en método: {metodo} con el token {token} y mensaje error: {mensaje}", nameof(GetPrincipal), token, ex.Message);
                throw;
            }
        }

        private ClienteConfig GetClienteConfig(Client cliente, string clientId, string apiKey)
        {
            // Consider moving hardcoded values to an static place
            return new ClienteConfig
            {
                ClientId = clientId,
                ApiKey = apiKey,
                NombreCliente = cliente.ClientName,
                Permisos = cliente?.Permissions,
                RequiereTerminal = cliente?.Metadata.GetBool("REQUIERE_TERMINAL"),
                PuedePreAutorizar = cliente?.Metadata.GetBool("PUEDE_PRE_AUTORIZAR"),
                EstadoPreAutorizado = cliente?.Metadata.GetInt("ESTADO_PRE_AUTORIZADO"),
                EstadoAperturado = cliente?.Metadata.GetInt("ESTADO_APERTURADO"),
                UsuarioIngresoReclamacion = cliente?.Metadata.GetString("USU_ING_RECLAMACION")
            };
        }

        private (string, string, string) CheckAndSetHeaders(HttpContext context)
        {
            var missingHeaders = new List<string>();

            if (!context.Request.Headers.TryGetValue(HeaderConstants.ClientId, out var clientId))
                missingHeaders.Add(nameof(HeaderConstants.ClientId));

            if (!context.Request.Headers.TryGetValue(HeaderConstants.ApiKey, out var apiKey))
                missingHeaders.Add(nameof(HeaderConstants.ApiKey));

            if (!context.Request.Headers.TryGetValue(HeaderConstants.Authorization, out var authHeader))
                if (RequiresUserToken(context)) missingHeaders.Add(nameof(HeaderConstants.Authorization));
            
            if (missingHeaders.Any())
                throw new UnauthorizedException($"These headers are required: {string.Join(", ", missingHeaders)}");

            var token = authHeader.ToString()?.Replace($"{HeaderConstants.AuthorizationType} ", string.Empty);
            return (clientId, apiKey, token);
        }

        private void ThrowIfNullOrEmpty(string str, string parameterName)
        {
            if (string.IsNullOrWhiteSpace(str))
                throw new UnauthorizedException($"{parameterName} is empty");
        }

        private void ThrowIfEmptyRequiredHeader(HttpContext context, string clientId, string apiKey, string token)
        {
            ThrowIfNullOrEmpty(clientId, nameof(clientId));
            ThrowIfNullOrEmpty(apiKey, nameof(apiKey));

            if (RequiresUserToken(context)) ThrowIfNullOrEmpty(token, nameof(token));
        }

        private static bool RequiresUserToken(HttpContext context)
        {
            return context.Features.Get<IEndpointFeature>().Endpoint?.Metadata?.Any(m => m is RequiereTokenUsuarioAttribute) ?? false;
        }
    }
}