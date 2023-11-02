using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace GestionAutorizaciones.Domain.Extensions
{
    public static class StringExtensions
    {
        public static IEnumerable<string> SplitPascalCase(this string source, bool findFirst = false)
        {
            string pattern = findFirst ? @"^([A-Z][a-z]*)|([A-Z][a-z]*|\d+)+" : @"[A-Z][a-z]*|[a-z]+|\d+";
            var matches = Regex.Matches(source, pattern);
            foreach (Match match in matches)
            {
                yield return match.Value;
            }

        }

        public static string ToLowerFirstLetter(this string source)
        {
            if (source == null || source.Length < 2)
                return source;

            return source.Substring(0, 1).ToLower() + source.Substring(1);
        }

        public static string ToCamelCase(this string source, string separatorPatter = @"[\w_]+")
        {
            if (source == null || source.Length < 2)
                return source;

            var matches = Regex.Matches(source, separatorPatter);
            string result = matches[0].Value.ToLower();
            for (int i = 1; i < matches.Count; i++)
            {
                result +=
                    matches[i].Value.Substring(0, 1).ToUpper() +
                    matches[i].Value.Substring(1);
            }

            return result;
        }
    }
}