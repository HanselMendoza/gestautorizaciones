using FluentMigrator.Runner;
using Microsoft.Extensions.DependencyInjection;
using System;

namespace GestionAutorizaciones.Migrations
{
    internal class Database
    {
        public static void RunMigrations(MigrationOptions migrationOptions)
        {
            var serviceProvider = CreateServices();

            using (var scope = serviceProvider.CreateScope())
            {
                var runner = scope.ServiceProvider.GetRequiredService<IMigrationRunner>();
                
                switch(migrationOptions.MigrationDirection) {
                    case MigrationDirection.Up:
                    if(migrationOptions.MigrationVersion > 0)
                        runner.MigrateUp(migrationOptions.MigrationVersion);
                    else
                        runner.MigrateUp();
                    break;
                    case MigrationDirection.Down:
                        runner.MigrateDown(migrationOptions.MigrationVersion);
                    break;
                }
            }
        }
        private static IServiceProvider CreateServices()
        {
            return new ServiceCollection()
                .AddFluentMigratorCore()
                .ConfigureRunner(rb => rb
                    .AddOracleManaged()
                    .WithGlobalConnectionString(Environment.GetEnvironmentVariable("CONNECTION_STRING"))
                    .ScanIn(typeof(Database).Assembly).For.Migrations())
                .AddLogging(lb => lb.AddFluentMigratorConsole())
                .BuildServiceProvider(false);
        }

    }
}
