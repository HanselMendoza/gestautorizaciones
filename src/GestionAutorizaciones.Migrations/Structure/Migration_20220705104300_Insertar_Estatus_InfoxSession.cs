using FluentMigrator;
using System;

namespace GestionAutorizaciones.Migrations.Structure
{
    [Migration(20220705104300, "Insertar Estatus InfoxSession")]
    public class Migration_20220705104300_Insertar_Estatus_InfoxSession : Migration
    {

        public override void Up()
        {
            Insert.IntoTable("ESTATUS").InSchema("DBAPER").
                Row(new {CODIGO = 268, DESCRIPCION = "PENDIENTE", VAL_LOG = "T",
                    TIPO = "INFOX_SESSION"}).
                Row(new {CODIGO = 269, DESCRIPCION = "ENVIADA", VAL_LOG = "T",
                    TIPO = "INFOX_SESSION"}).
                Row(new {CODIGO = 270, DESCRIPCION = "PREAUTORIZADA", VAL_LOG = "T",
                    TIPO = "INFOX_SESSION"}).
                Row(new {CODIGO = 271, DESCRIPCION = "CANCELADA", VAL_LOG = "F",
                    TIPO = "INFOX_SESSION"}).
                Row(new {CODIGO = 272, DESCRIPCION = "ABIERTA", VAL_LOG = "T",
                    TIPO = "INFOX_SESSION"});
        }

        public override void Down()
        {
            Delete.FromTable("ESTATUS").InSchema("DBAPER").
                Row(new {CODIGO = 268}).
                Row(new {CODIGO = 269}).
                Row(new {CODIGO = 270}).
                Row(new {CODIGO = 271}).
                Row(new {CODIGO = 272});
        }
    }
}
