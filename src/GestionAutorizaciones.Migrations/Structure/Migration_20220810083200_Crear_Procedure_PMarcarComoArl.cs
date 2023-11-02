using FluentMigrator;
using System;
using System.Linq;

namespace GestionAutorizaciones.Migrations.Structure
{
    [Migration(20220810083200, "Crear Procedure P_MARCAR_COMO_ARL")]
    public class Migration_20220810083200_Crear_Procedure_PMarcarComoArl : BaseScriptMigration
    {
        private readonly string[] _scripts = {"P_MARCAR_COMO_ARL"};
        protected override string DefaultSchema() => "AUTORIZACIONES";
        protected override string BaseScriptPath() => "Sql/";
        public override void Up()
        {
            _scripts.ToList().
                ForEach(script => CreateOrReplace(script,$"{script}.sql"));
        }

        public override void Down()
        {
            _scripts.Reverse().ToList().
                ForEach(script => DropObject(StoredObject.Procedure, script));
        }
    }
}
