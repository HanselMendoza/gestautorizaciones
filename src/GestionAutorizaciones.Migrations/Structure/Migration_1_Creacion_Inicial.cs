using FluentMigrator;
using System;

namespace GestionAutorizaciones.Migrations.Structure
{
    [Migration(1, "Creacion_Inicial")]
    public class Migration_1_Creacion_Inicial : BaseScriptMigration
    {
        protected override string DefaultSchema() => "AUTORIZACIONES";
        protected override string BaseScriptPath() => ".SQL/Initial/";
        public override void Up()
        {
            CreateObject("DBAPER", "ESTATUS", "CREAR_TABLA_ESTATUS.sql");
            CreateObject("DBAPER", "INFOX_SESSION", "CREAR_TABLA_INFOX_SESSION.sql");
        }

        public override void Down()
        {
            //Aquí se eliminan los objetos creados en orden inverso, deshabilitando primero
            //los constraints correspondientes.
            //También podría invocarse un script de eliminación
        }
    }
}