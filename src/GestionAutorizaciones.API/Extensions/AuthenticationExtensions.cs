using System;
using System.Linq;
using System.Collections.Generic;
using AuthenticationAPI.Driver.Models;
namespace GestionAutorizaciones.Application.Auth.DTOs
{
    public static class AuthenticationExtensions
    {
        public static bool? GetBool(this ICollection<Metadata> metadata, string key)
        {
            if (metadata == null) return default;
            var value = metadata.Where(x => x.Key == key).Select(x => x.Value).FirstOrDefault()?.ToLower();
            
            var boolValue = default(bool?);
            try { boolValue = Convert.ToBoolean(value); }
            catch (Exception) {}

            return boolValue;
        }

        public static int? GetInt(this ICollection<Metadata> metadata, string key)
        {
            if (metadata == null) return default;
            var value = metadata.Where(x => x.Key == key).Select(x => x.Value).FirstOrDefault();

            int? intValue = default(int?);
            try { intValue = Int32.Parse(value); }
            catch (Exception) {}

            return intValue;
        }

        public static string GetString(this ICollection<Metadata> metadata, string key)
        {
            if (metadata == null) return default;
            return metadata.Where(x => x.Key == key).Select(x => x.Value).FirstOrDefault();
        }
    }
}