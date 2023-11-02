
namespace GestionAutorizaciones.API.Utils
{
    public static class ApiVersions
    {
        public const string v1 = "1.0";
        public const string v2 = "2.0";
    }

    public static class Routes
    {
        public const string GlobalPrefix = "api/v{version:apiVersion}";
        public const string AutorizacionesController = "";
        public const string GenericController = "autorizaciones/[controller]";
    }

    public static class HeaderConstants
    {
        public const string Authorization = "Authorization";
        public const string AuthorizationType = "Bearer";
        public const string NumeroSesion = "x-numero-sesion";
        public const string ClientId = "clientId";
        public const string ApiKey = "apiKey";
    }

    public static class HttpContextItems
    {
        public const string ClienteConfig = "ClienteConfig";
    }
}

