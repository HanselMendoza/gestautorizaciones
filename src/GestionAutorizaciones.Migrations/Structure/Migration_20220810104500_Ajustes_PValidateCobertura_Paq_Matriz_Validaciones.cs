using FluentMigrator;
using System;
using System.Linq;

namespace GestionAutorizaciones.Migrations.Structure
{
    [Migration(20220810104500, "Ajustes P_VALIDATE_COBERTUAR por cambios en PAQ_MATRIZ_VALIDACIONES")]
    public class Migration_20220810104500_Ajustes_PValidateCobertura_Paq_Matriz_Validaciones : BaseScriptMigration
    {
        private readonly string[] _scripts = {"P_VALIDATECOBERTURA_LOC",
                                            "P_VALIDATECOBERTURA_INT",
                                            "P_VALIDATECOBERTURA"};
        protected override string DefaultSchema() => "AUTORIZACIONES";
        protected override string BaseScriptPath() => "Sql/20220810104500/";
        public override void Up()
        {
            _scripts.ToList().
                ForEach(script => CreateOrReplace(script,$"{script}_20220810104500.sql"));
        }

        public override void Down()
        {
            _scripts.Reverse().ToList().
                ForEach(proc => DropObject(StoredObject.Procedure, proc));
        }
    }
}
