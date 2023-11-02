using System;
using System.Linq;

namespace GestionAutorizaciones.Migrations
{
    public class Program
    {
        static void Main(string[] args)
        {
            try
            {
                var migrationOptions = ParseArguments(args);

                Console.WriteLine("Corriendo las migraciones ...");
                Database.RunMigrations(migrationOptions);
                Console.WriteLine("Migraciones finalizadas.");
            }
            catch(ArgumentException argEx) {
                if(!string.IsNullOrEmpty(argEx.Message))
                    Console.WriteLine(argEx.Message);
                PrintArguments();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ha ocurrido una excepción: {ex.Message}");
            }
        }

        static MigrationOptions ParseArguments(string[] args)
        {
            var result = new MigrationOptions();
            if (args.Length > 0)
            {
                //Si tiene el argumento ayuda
                if(HasParam(args,"-h")) {
                    throw new ArgumentException();
                }
                //Encuentra el argumento dirección
                var direccionMigracion = GetParamValue(args, "-d");
                result.MigrationDirection = CastMigrationDirection(direccionMigracion);
                //Encuentra el argumento versión de la migración
                var versionMigracion = GetParamValue(args, "-v");
                result.MigrationVersion = CastMigrationVersion(versionMigracion);
            }
            return result;
        }

        private static long CastMigrationVersion(string versionMigracion)
        {
            long result = 0;
            if (string.IsNullOrEmpty(versionMigracion))
                return result;

            if (!long.TryParse(versionMigracion, out result))
                throw new ArgumentException("Debe especificar un número de migración válido");
            return result;
        }

        private static MigrationDirection CastMigrationDirection(string direccionMigracion)
        {
            if (string.IsNullOrEmpty(direccionMigracion))
                return MigrationDirection.Up;

            return (MigrationDirection)Enum.Parse(typeof(MigrationDirection), direccionMigracion, true);
        }

        static bool HasParam(string[] args, string param)
        {
            return args.Contains(param);
        }
        static string GetParamValue(string[] args, string param)
        {
            var dirIndex = Array.IndexOf(args, param);
            if(dirIndex < 0)
                return null;
            if (args.Length > dirIndex + 1)
                return args[dirIndex + 1];
            else
                throw new ArgumentException($"Falta valor para el parámetro {param}");
        }

        static void PrintArguments()
        {
            Console.WriteLine("Ej: [-d up|down] [-v 20220523203100]\n");
            Console.WriteLine("-d   Indica la dirección de corrida de las migraciones. ");
            Console.WriteLine("     puede ser hacia arriba (up), de antiguo a reciente, ");
            Console.WriteLine("     o hacia abajo (down), de reciente a más antiguo. ");
            Console.WriteLine("     Este parámetro no es sensible a las mayúsculas. \n");
            Console.WriteLine("-v   Sirve para indicar si se correrá hasta una migración en específico.\n");
        }
    }
}