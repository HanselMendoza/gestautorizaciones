using System.Threading.Tasks;
using AuthenticationAPI.Driver.Models;

namespace GestionAutorizaciones.Application.Auth.Common
{
    public interface IAuthService
    {
        Task<(TokenGenerated, ResponseDTO)> Login(string clientId, string apiKey, string username, string password);
        Task<(bool, string)> ValidateToken(string apiKey, string clientId, string accessToken);
        Task<(TokenGenerated, ResponseDTO)> RefreshToken(string clientId, string apiKey, string expiredToken, string accessToken);
        Task<(Client, ResponseDTO)> GetCurrentClient(string clientId, string apiKey);
        Task<(User, ResponseDTO)> GetCurrentUser(string clientId, string apiKey, string accessToken);
    }
}
