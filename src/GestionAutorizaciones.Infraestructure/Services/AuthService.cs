using System;
using System.Threading.Tasks;
using AuthenticationAPI.Driver;
using AuthenticationAPI.Driver.Models;
using GestionAutorizaciones.Application.Auth.Common;

namespace GestionAutorizaciones.Infraestructure.Services
{
    public class AuthService : IAuthService
    {
        private AuthenticationClient _authenticationClient;
        private readonly string _authenticationHost;

        public AuthService()
        {
            _authenticationHost = Environment.GetEnvironmentVariable("HOST_AUTHENTICATION_API");
        }

        private AuthenticationClient SetAuthenticationClient(string clientId, string apiKey)
        {
            _authenticationClient = new AuthenticationClient(_authenticationHost, clientId, apiKey);
            return _authenticationClient;
        }

        public async Task<(TokenGenerated, ResponseDTO)> Login(string clientId, string apiKey, string username, string password)
        {
            SetAuthenticationClient(clientId, apiKey);
            var (token, response) = await _authenticationClient.Login(username, password);
            return (token, response);
        }

        public async Task<(bool, string)> ValidateToken(string clientId, string apiKey, string accessToken)
        {
            SetAuthenticationClient(clientId, apiKey);
            var (isValid, message) = await _authenticationClient.ValidateToken(accessToken);
            return (isValid, message);
        }

        public async Task<(TokenGenerated, ResponseDTO)> RefreshToken(string clientId, string apiKey, string expiredToken, string accessToken)
        {
            SetAuthenticationClient(clientId, apiKey);
            var (token, response) = await _authenticationClient.RefreshToken(expiredToken, accessToken);
            return (token, response);
        }

        public async Task<(Client, ResponseDTO)> GetCurrentClient(string clientId, string apiKey)
        {
            SetAuthenticationClient(clientId, apiKey);
            var (client, response) = await _authenticationClient.GetCurrentClient();
            return (client, response);
        }

        public async Task<(User, ResponseDTO)> GetCurrentUser(string clientId, string apiKey, string accessToken)
        {
            SetAuthenticationClient(clientId, apiKey);
            var (user, response) = await _authenticationClient.GetCurrentUser(accessToken);
            return (user, response);
        }
    }
}
