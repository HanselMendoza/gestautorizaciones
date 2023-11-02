using FluentMigrator;
using System;
using GestionAutorizaciones.Migrations.Extensions;

namespace GestionAutorizaciones.Migrations.Structure
{
    [Migration(20220704204300, "Alterar Tabla InfoxSession. Agregar campos")]
    public class Migration_20220704204300_Fluent_Alterar_Tabla_InfoxSession : Migration
    {
        const string _nombreSchema = "DBAPER";
        const string _nombreTabla = "INFOX_SESSION";

        public override void Up()
        {
            Alter.Table(_nombreTabla).InSchema(_nombreSchema).
                AddColumn("ESTATUS").AsNumber(3).Nullable().
                    WithColumnDescription("Código de Estatus de la Autorización en el ciclo de vida de la Sesión").
                AddColumn("ORIGEN").AsVarchar2(20).Nullable().
                    WithColumnDescription("(ARS, ASE) Es una abreviatura para la Compañía Orígen del Asegurado (Primera o Humano). Este campo se eliminará en una refactorización posterior").
                AddColumn("CANAL").AsVarchar2(50).Nullable().
                    WithColumnDescription("Canal a través del cual se realiza esta sesión (WEBSALUD, FONOSALUD, WEBSERVICE, KIOSKO, ETC.)").
                AddColumn("USUARIO_WS").AsVarchar2(50).Nullable().
                    WithColumnDescription("Nombre de usuario del webservice otorgado al prestador que creó esta sesión").
                AddColumn("ES_SOLO_PBS").AsChar(1).WithDefaultValue('N').
                    WithColumnDescription("Indica si el asegurado de esta sesión únicamente posee plan básico").
                AddColumn("ES_PSS_PAQUETE").AsChar(1).WithDefaultValue('N').
                    WithColumnDescription("Indica si el prestador pertenece a un paquete").
                AddColumn("API_KEY").AsVarchar2(40).Nullable().
                    WithColumnDescription("Api Key asignado al prestador que creó esta sesión. Se remueve al cerrar sesión o reactivar sesiones").
                AddColumn("TOKEN").AsVarchar2(1100).Nullable().
                    WithColumnDescription("Token generado por el servicio de autenticación para autorizar esta sesión.").
                AddColumn("NUMSESSION_ORIGEN").AsNumber(12).Nullable().
                    WithColumnDescription("Número de sesión original, si esta es una sesión reactivada.").
                AddColumn("TIENE_EXCESOPORGRUPO").AsChar(1).WithDefaultValue('N').
                    WithColumnDescription("Indica si el asegurado Excede el Monto de Beneficio por Grupo para la Última cobertura validada. Se pone en NULL al final de p_insertcobertura");

            AddCheckConstraint(_nombreTabla, "CHK_INFOX_SESSION_EXCPORGRUPO",
                "TIENE_EXCESOPORGRUPO IN ('S', 'N')", enable: true);

        }

        public override void Down()
        {
            Delete.Column("ESTATUS").FromTable(_nombreTabla).InSchema(_nombreSchema);
            Delete.Column("ORIGEN").FromTable(_nombreTabla).InSchema(_nombreSchema);
            Delete.Column("CANAL").FromTable(_nombreTabla).InSchema(_nombreSchema);
            Delete.Column("USUARIO_WS").FromTable(_nombreTabla).InSchema(_nombreSchema);
            Delete.Column("ES_SOLO_PBS").FromTable(_nombreTabla).InSchema(_nombreSchema);
            Delete.Column("ES_PSS_PAQUETE").FromTable(_nombreTabla).InSchema(_nombreSchema);
            Delete.Column("API_KEY").FromTable(_nombreTabla).InSchema(_nombreSchema);
            Delete.Column("TOKEN").FromTable(_nombreTabla).InSchema(_nombreSchema);
            Delete.Column("NUMSESSION_ORIGEN").FromTable(_nombreTabla).InSchema(_nombreSchema);
            Delete.Column("TIENE_EXCESOPORGRUPO").FromTable(_nombreTabla).InSchema(_nombreSchema);

        }

        private void AddCheckConstraint(string tableName, string constraintName, string condition, bool enable = false)
        {
            Execute.Sql($"ALTER TABLE \"{_nombreSchema}\".\"{ tableName}\" " +
                $"ADD CONSTRAINT \"{constraintName}\" " +
                $"CHECK ({condition}) {(enable ? "ENABLE":"")}");

        }
    }
}