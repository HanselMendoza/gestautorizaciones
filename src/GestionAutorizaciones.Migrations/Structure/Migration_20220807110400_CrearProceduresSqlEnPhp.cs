using FluentMigrator;
using System;
using System.Linq;

namespace GestionAutorizaciones.Migrations.Structure
{
    [Migration(20220807110400, "Creación Inicial Procedures SQL embebido en PHP")]
    public class Migration_20220807110400_CrearProceduresSqlEnPhp : BaseScriptMigration
    {
        private readonly string[] _scripts = {"P_ACTUALIZA_INFOX_SESSION",
            "P_ASEGURADO_TIENE_SOLO_PBS",
            "P_BUSCA_AFILIADO",
            "P_COB_REQUIERE_PRESCRIPTOR",
            "P_CONFIRMAR_RECLAMACION",
            "P_DATOS_PRECERTIFICACION",
            "P_DETERMINA_ORIGEN_POR_NUM_PLA",
            "P_ES_COBERTURA_CONSULTA",
            "P_ES_COBERTURA_LABORATORIO",
            "P_ES_PSS_PAQUETE",
            "P_OBTENER_DET_RECLAMACION",
            "P_OBTENER_INFOX_SESSION",
            "P_OBTENER_INFO_PSS",
            "P_OBTENER_INFO_RECLAMACION",
            "P_OBTENER_NUCLEO_POR_NUM_PLA",
            "P_OBTENER_PROCEDIMIENTOS_PSS",
            "P_OBTENER_RECLAMACION",
            "P_OBTENER_RECLAMACIONES_PSS",
            "P_OBTENER_TELEFONO_PLASTICO",
            "P_OBTENER_TIPO_PSS",
            "P_PUEDE_PSS_DAR_SERVICIO",
            "P_PUEDE_PSS_OFRECER_TIP_COB",
            "P_REACTIVAR_SESSION",
            "P_VALIDA_PRECERTIFICACION",
            "P_VALIDA_REGLAS_COBERTURA"};
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
