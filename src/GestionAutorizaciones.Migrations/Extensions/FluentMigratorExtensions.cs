using FluentMigrator.Builders.Alter.Table;

namespace GestionAutorizaciones.Migrations.Extensions
{
    public static class FluentMigratorExtensions {

        public static IAlterTableColumnOptionOrAddColumnOrAlterColumnSyntax AsVarchar2(this IAlterTableColumnAsTypeSyntax colBuilder, int size){
            return colBuilder.AsCustom($"VARCHAR2({size})");
        }

        public static IAlterTableColumnOptionOrAddColumnOrAlterColumnSyntax AsChar(this IAlterTableColumnAsTypeSyntax colBuilder, int size){
            return colBuilder.AsCustom($"CHAR({size})");
        }

        public static IAlterTableColumnOptionOrAddColumnOrAlterColumnSyntax AsNumber(this IAlterTableColumnAsTypeSyntax colBuilder, 
        int size, int precision = 0){
            return colBuilder.AsCustom($"NUMBER({size},{precision})");
        } 
    }
}