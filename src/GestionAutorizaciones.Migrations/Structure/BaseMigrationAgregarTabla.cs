using FluentMigrator;
using System;

namespace GestionAutorizaciones.Migrations.Structure
{
    public abstract class BaseMigrationAgregarTabla : Migration
    {
        protected abstract string NombreTabla();
        protected abstract string NombreSchema();

        public override void Up()
        {
            if (Schema.Schema(NombreSchema()).Table(NombreTabla()).Exists())
            {
                Console.WriteLine($"Tabla {NombreTabla()} ya existe!");
                return;
            }
        }
        protected bool TableExists() {
            var exists = Schema.Schema(NombreSchema()).Table(NombreTabla()).Exists();
            if (exists)
            {
                Console.WriteLine($"La tabla {NombreTabla()} ya existe!");
            }
            return exists;
        }

        public override void Down()
        {
            if(!Schema.Schema(NombreSchema()).Table(NombreTabla()).Exists()) {
                Console.WriteLine($"La tabla {NombreTabla()} no existe!");
                return;
            }

            Delete.Table(NombreTabla()).InSchema(NombreSchema());
        }
    }
}
