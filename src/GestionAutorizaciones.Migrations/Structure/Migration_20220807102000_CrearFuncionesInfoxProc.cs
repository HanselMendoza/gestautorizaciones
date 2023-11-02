using FluentMigrator;
using System;

namespace GestionAutorizaciones.Migrations.Structure
{
    [Migration(20220807102000, "Creación Inicial Funciones INFOXPROC")]
    public class Migration_20220807102000_CrearFuncionesInfoxProc : BaseScriptMigration
    {
        protected override string DefaultSchema() => "AUTORIZACIONES";
        protected override string BaseScriptPath() => "Sql/";
        public override void Up()
        {
            CreateOrReplace("F_BUSCA_COB_ESTUDIO_REPETICION", "F_BUSCA_COB_ESTUDIO_REPETICION.sql");
            CreateOrReplace("F_BUSCA_ORIGEN_COB_MON_MAX", "F_BUSCA_ORIGEN_COB_MON_MAX.sql");
            CreateOrReplace("F_BUSCAR_DATOS_COBERTURA", "F_BUSCAR_DATOS_COBERTURA.sql");
        }

        public override void Down()
        {
            DropObject(StoredObject.Function, "F_BUSCAR_DATOS_COBERTURA");
            DropObject(StoredObject.Function, "F_BUSCA_ORIGEN_COB_MON_MAX");
            DropObject(StoredObject.Function, "F_BUSCA_COB_ESTUDIO_REPETICION");

        }
    }
}
