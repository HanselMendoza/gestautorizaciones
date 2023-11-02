using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;

namespace GestionAutorizaciones.Domain.Extensions
{
    public static class EnumExtensions
    {
        public static string GetName(this Enum enumValue)
        {
            return enumValue.ToString();
        }

        public static string GetDescription(this Enum enumValue)
        {
            var result = enumValue.GetName();
            var field = enumValue.GetType().GetField(result);
            if (Attribute.GetCustomAttribute(field, typeof(DescriptionAttribute)) is DescriptionAttribute attribute)
            {
                result = attribute.Description;
            }
            return result;
        }

        public static IEnumerable<T> GetValues<T>(this Type enumType)
        {
            if (enumType == null) throw new NullReferenceException();
            if (!enumType.IsEnum) throw new InvalidCastException("object is not an Enumeration");
            return Enum.GetValues(enumType).Cast<T>();
        }

        public static int CountValues(this Type enumType)
        {
            if (enumType == null) throw new NullReferenceException();
            if (!enumType.IsEnum) throw new InvalidCastException("object is not an Enumeration");
            return Enum.GetValues(enumType).Length;
        }

    }
}