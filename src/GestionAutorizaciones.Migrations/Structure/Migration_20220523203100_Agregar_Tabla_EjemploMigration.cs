using FluentMigrator;
using System;

namespace GestionAutorizaciones.Migrations.Structure
{
    public class Migration_20220523203100_Agregar_Tabla_EjemploMigration : Migration
    {
        const string _nombreTabla = "EjemploMigration";

        public override void Up()
        {
            if (Schema.Table(_nombreTabla).Exists())
            {
                Console.WriteLine(@$"Tabla {{_nombreTabla}} ya existe!");
                return;
            }
            Create.Table(_nombreTabla)
                .WithColumn("Id").AsInt64().PrimaryKey("PK_EjemploMigration")
                .WithColumn("Text").AsFixedLengthString(100);
        }

        public override void Down()
        {
            Delete.Table(_nombreTabla);
        }
    }
}
