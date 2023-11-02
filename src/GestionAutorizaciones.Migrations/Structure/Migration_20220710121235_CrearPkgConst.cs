using FluentMigrator;
using System;

namespace GestionAutorizaciones.Migrations.Structure
{
    [Migration(20220710121235, "Crear Package PKG_CONST")]
    public class Migration_20220710121235_CrearPkgConst : BaseScriptMigration
    {
        protected override string DefaultSchema() => "AUTORIZACIONES";
        protected override string BaseScriptPath() => "Sql/";
        private string _objectName = "PKG_CONST";
        public override void Up() => CreateOrReplace(_objectName, "PKG_CONST.sql");

        public override void Down() => DropObject(StoredObject.Package, _objectName);
    }
}
