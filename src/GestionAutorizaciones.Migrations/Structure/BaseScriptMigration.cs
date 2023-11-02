using FluentMigrator;
using System;
using GestionAutorizaciones.Domain.Extensions;

namespace GestionAutorizaciones.Migrations.Structure
{
    public abstract class BaseScriptMigration : Migration
    {
        protected abstract string DefaultSchema();
        protected abstract string BaseScriptPath();

        public enum StoredObject {
            Package,
            Procedure,
            Function,
            Type
        }
        protected void CreateObject(string schemaName, string objectName, string script)
        {
            if (Schema.Schema(schemaName).Table(objectName).Exists())
            {
                Console.WriteLine($"El objeto {objectName} ya existe!");
            }
            else
            {
                Console.WriteLine($"Creando objeto {objectName}...");
                Execute.Script(BaseScriptPath()+script);
            }
        }
        protected void CreateObject(string objectName, string script)
        {
            CreateObject(DefaultSchema(), objectName, script);
        }

        protected void ModifyObject(string schemaName, string objectName, string script)
        {
            if (Schema.Schema(schemaName).Table(objectName).Exists())
            {
                Console.WriteLine($"Alterando el objeto {objectName}...");
                Execute.Script(BaseScriptPath() + script);
            }
            else
            {
                Console.WriteLine($"El objeto {objectName} no existe!");
            }
        }

        protected void ModifyObject(string objectName, string script)
        {
            ModifyObject(DefaultSchema(), objectName, script);
        }

        protected void CreateOrReplace(string objectName, string script)
        {
            Console.WriteLine($"Creando o reemplazando el objeto {objectName}...");
            Execute.Script(BaseScriptPath() + script);

        }

        protected void DropObject(StoredObject storedObject, string objectName)
        {
            if(objectName == null) {
                throw new ArgumentException("Debe especificar el objeto a eliminar");
            }
            string objectType = storedObject.GetDescription().ToUpper();
            var sql = $"DROP {objectType} {objectName}";
            Console.WriteLine($"Eliminando el objeto {objectType} {objectName}...");
            Execute.Sql(sql);
        }
    }
}
