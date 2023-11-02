using FluentMigrator;
using System;
using System.Linq;

namespace GestionAutorizaciones.Migrations.Structure
{
    [Migration(20220807102100, "Creación Inicial Procedures INFOXPROC")]
    public class Migration_20220807102100_CrearProceduresInfoxProc : BaseScriptMigration
    {
        private readonly string[] _scripts = {
                "P_ACTIVAR_PRECERTIFICACION",
                "P_CALCULAR_RESERVA",
                "P_CLOSE_PRECERTIFICACION",
                "P_CLOSERECLAMACION",
                "P_CLOSESESSION",
                "P_DELETECOBERTURA",
                "P_DELETERECLAMACION",
                "P_INGRESO_FROM_RECLAMAC",
                "P_INSERTCOBERTURA",
                "P_INSERTCOBERTURA_PRECERTIF",
                "P_OPEN_PRECERTIF",
                "P_OPENRECLAMACION",
                "P_OPENSESSION",
                "P_RESUMENRECLAMACION",
                "P_VALIDATEASEGURADO_LOC",
                "P_VALIDATEASEGURADO",
                "P_VALIDATECOBERTURA_INT",
                "P_VALIDATECOBERTURA_LOC",
                "P_VALIDATECOBERTURA",
                "P_VALIDATEPIN",
                "P_VALIDATEPINTRATANTE",
                "P_VALIDATERECLAMACION",
                "INFOXPROC"};

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
