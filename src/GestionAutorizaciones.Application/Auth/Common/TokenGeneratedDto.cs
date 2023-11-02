namespace GestionAutorizaciones.Application.Auth.Common
{
    public class TokenGeneratedDto
    {
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
    }
}
