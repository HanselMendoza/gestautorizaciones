--------------------------------------------------------
--  DDL for Table ESTATUS
--------------------------------------------------------

  CREATE TABLE "DBAPER"."ESTATUS" 
   (	"CODIGO" NUMBER(3,0), 
	"DESCRIPCION" VARCHAR2(40 BYTE), 
	"VAL_LOG" VARCHAR2(1 BYTE) DEFAULT 'T', 
	"TIPO" VARCHAR2(30 BYTE), 
	"COMENT" VARCHAR2(256 BYTE), 
	"VAL_L_REC" VARCHAR2(1 BYTE) DEFAULT 'T', 
	"TIP_CCO" VARCHAR2(2 BYTE)
   ) ;

   COMMENT ON COLUMN "DBAPER"."ESTATUS"."CODIGO" IS 'Clave del estatus';
   COMMENT ON COLUMN "DBAPER"."ESTATUS"."DESCRIPCION" IS 'Descripcion del estatus';
   COMMENT ON COLUMN "DBAPER"."ESTATUS"."VAL_LOG" IS 'Valor logico (true or false) del estatus';
   COMMENT ON COLUMN "DBAPER"."ESTATUS"."TIPO" IS 'Tipo de estatus';
   COMMENT ON COLUMN "DBAPER"."ESTATUS"."COMENT" IS 'Comentarios sobre el estatus';
   COMMENT ON COLUMN "DBAPER"."ESTATUS"."VAL_L_REC" IS 'Valor logico (true or false) del estatus';
   COMMENT ON TABLE "DBAPER"."ESTATUS"  IS 'Estatus';
--------------------------------------------------------
--  DDL for Index IDX$$_4551B0002
--------------------------------------------------------

  CREATE INDEX "DBAPER"."IDX$$_4551B0002" ON "DBAPER"."ESTATUS" ("VAL_LOG", "TIPO", "TIP_CCO", "CODIGO") 
  ;
--------------------------------------------------------
--  DDL for Index IDXESTTIPO
--------------------------------------------------------

  CREATE INDEX "DBAPER"."IDXESTTIPO" ON "DBAPER"."ESTATUS" ("TIPO") 
  ;
--------------------------------------------------------
--  DDL for Index ESTATUS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "DBAPER"."ESTATUS_PK" ON "DBAPER"."ESTATUS" ("CODIGO") 
  ;
--------------------------------------------------------
--  DDL for Index IDX$$_3E6A40005
--------------------------------------------------------

  CREATE INDEX "DBAPER"."IDX$$_3E6A40005" ON "DBAPER"."ESTATUS" ("VAL_LOG", "TIPO", "CODIGO") 
  ;
--------------------------------------------------------
--  DDL for Index IDX$$_3ED290002
--------------------------------------------------------

  CREATE INDEX "DBAPER"."IDX$$_3ED290002" ON "DBAPER"."ESTATUS" ("VAL_LOG", "TIPO", "VAL_L_REC", "CODIGO") 
  ;
--------------------------------------------------------
--  DDL for Index IDX$$_3ED740006
--------------------------------------------------------

  CREATE INDEX "DBAPER"."IDX$$_3ED740006" ON "DBAPER"."ESTATUS" ("TIP_CCO", "TIPO", "CODIGO") 
  ;
--------------------------------------------------------
--  Constraints for Table ESTATUS
--------------------------------------------------------

  ALTER TABLE "DBAPER"."ESTATUS" ADD CONSTRAINT "ESTATUS_PK" PRIMARY KEY ("CODIGO")
  USING INDEX  ENABLE;
  ALTER TABLE "DBAPER"."ESTATUS" ADD CHECK ( val_l_rec IN ( 'T' , 'F' )  ) ENABLE;
  ALTER TABLE "DBAPER"."ESTATUS" ADD CHECK ( val_log IN ( 'T' , 'F' )  ) ENABLE;
  ALTER TABLE "DBAPER"."ESTATUS" MODIFY ("VAL_L_REC" NOT NULL ENABLE);
  ALTER TABLE "DBAPER"."ESTATUS" MODIFY ("TIPO" NOT NULL ENABLE);
  ALTER TABLE "DBAPER"."ESTATUS" MODIFY ("VAL_LOG" NOT NULL ENABLE);
  ALTER TABLE "DBAPER"."ESTATUS" MODIFY ("DESCRIPCION" NOT NULL ENABLE);
  ALTER TABLE "DBAPER"."ESTATUS" MODIFY ("CODIGO" NOT NULL ENABLE);
