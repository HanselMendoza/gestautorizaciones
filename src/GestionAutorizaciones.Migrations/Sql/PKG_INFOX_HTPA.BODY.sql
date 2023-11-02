CREATE OR REPLACE PACKAGE BODY DBAPER.pkg_infox_htpa IS
--
--FAVOR DE VERSIONAR Y COMENTAR ESTE PACKGE COMO EN ESTOS EJEMPLOS--
--FAVOR DE VERSIONAR Y COMENTAR ESTE PACKGE COMO EN ESTOS EJEMPLOS--
--FAVOR DE VERSIONAR Y COMENTAR ESTE PACKGE COMO EN ESTOS EJEMPLOS--
--
/****************************V 1.03****************************
||Modificado por    : Waldy Robinson Sanchez (wrs)
||Comentario        : se comento el codigo dond al servicio cuando
||                    venia 6 le asinaba un 8 y se creo la modificacion
||                    para que se quede con el 6. para que funcione el
||                    servicio 6.
||Fecha             : 22/09/2021
||Version           : 1.00
||inicidente        : 118608
***************************************************************/
--
  --*** ESTE PAQUETE INCLUYE LOS CAMBIOS REALIZADOS EN 11/2019 PARA CANALES EN MIGRACION DE SALUD INTERNACIONAL
  --*** suministrado por MCarrion con los ultimos cambios de Produccion. 25/02/2020

  V_DEDUCIBLE_MIREX         NUMBER(30);
  V_ANO_SERVICIO            NUMBER;
  V_EDAD_AFILIADO           NUMBER;
  vMESSAGE                  VARCHAR2(2000); --- MENSAJE DEL EXCESO POR GRUPO
  V_MONPAG_DEVUELVE_FUNCION NUMBER;
  vUSUARIO                  VARCHAR2(15);
  vCANAL                    RECLAMACION.CANAL%TYPE;

  V_1         CONSTANT NUMBER(3) := 1;
  V_6         CONSTANT NUMBER(3) := 6;
  V_7         CONSTANT NUMBER(3) := 7;
  V_8         CONSTANT NUMBER(3) := 8;
  V_25        CONSTANT NUMBER(3) := 25;
  V_40        CONSTANT NUMBER(3) := 40;
  V_46        CONSTANT NUMBER(3) := 46;
  V_56        CONSTANT NUMBER(3) := 56;
  V_57        CONSTANT NUMBER(3) := 57;
  V_83        CONSTANT NUMBER(5) := 83;
  V_122       CONSTANT NUMBER(5) := 122;
  V_229       CONSTANT NUMBER(5) := 229;
  V_230       CONSTANT NUMBER(5) := 230;
  V_1166      CONSTANT NUMBER(5) := 1166;
  V_S         CONSTANT VARCHAR2(1) := 'S';
  V_T         CONSTANT VARCHAR2(1) := 'T';
  V_NO_MEDICO CONSTANT VARCHAR2(10) := 'NO_MEDICO';
  V_MEDICO    CONSTANT VARCHAR2(10) := 'MEDICO';
  V_AC_SERV   CONSTANT NUMBER(3) := 13;
  V_COB_AC    CONSTANT NUMBER := 3023;
    f_fec_ver                 DATE;
  --
  V_FEC_FINAL               DATE;
  V_FEC_FINAL_GMM           DATE       := NULL;
  --
  v_bce_ac                  NUMBER(14,2) :=0;
  v_lim_ac                  NUMBER(14,2) :=0;
  v_total_consumo           NUMBER(14,2) :=0;
  Valor_max_ac              NUMBER(14,2) :=0;
  valor_max_gmm             NUMBER(14,2) :=0;
  balance_gmm               NUMBER := 0;
  V_NSS                     NUMBER(9);
  V_plasticos               NUMBER;

  --
  V_PLAN_PBS                NUMBER(3);
  V_COMPANIA_PBS            NUMBER(2);
  V_RAMO_PBS                NUMBER(2);
  V_SEC_PBS                 NUMBER(7);

  --mcarrion-con
  V_SIMULTANEO VARCHAR2(1);
--
   V_MONTO_COBER  NUMBER(11,2);
   V_ERROR       NUMBER;
   V_DESC_ERROR  VARCHAR2(100);


 V_NOTAS       VARCHAR2(100);
  VAR_TIP_REC       POL_P_SER.TIP_REC%TYPE; /* Almacena el Tipo de Reclamante('ASEGURADO', 'MEDICO', etc.)  */
  --
  P_CANTIDAD NUMBER;
  P_FEC_VER  DATE;
  P_FEC_FIN  DATE;
  P_SERVICIO NUMBER;
  P_TIP_COB  NUMBER;
  P_ERROR    NUMBER;

  PROCEDURE P_USUARIO_FONO IS
  BEGIN
    vUsuario := null;
    vUsuario := f_busca_usu_registra_canales(user);

    IF vUsuario is null then
      vUsuario := 'FONOSALUD';
    end if;
    --
    vCANAL := PKG_PRE_CERTIFICACIONES.F_OBTEN_CANAL_AUT(vUsuario);
    --
  END;

  PROCEDURE P_VALIDATEPINTRATANTE(p_name       IN VARCHAR2,
                                  p_numsession IN NUMBER,
                                  p_instr1     IN VARCHAR2,
                                  p_instr2     IN VARCHAR2,
                                  p_innum1     IN NUMBER,
                                  p_innum2     IN NUMBER,
                                  p_outstr1    OUT VARCHAR2,
                                  p_outstr2    OUT VARCHAR2,
                                  p_outnum1    OUT NUMBER,
                                  p_outnum2    OUT NUMBER) IS
  BEGIN
    Declare
      FONOS_ROW INFOX_SESSION%ROWTYPE;
      f_codigo  number(7);
      --
      CURSOR F IS
        SELECT Codigo, 'DR. ' || MEDICO.PRI_NOM || ' ' || MEDICO.PRI_APE
          FROM MEDICO MEDICO
         WHERE MEDICO.CODIGO = p_instr1
           AND TRUNC(SYSDATE) >= TRUNC(FEC_ING)
           AND MEDICO.ESTATUS = (SELECT CODIGO
                                   FROM ESTATUS
                                  WHERE CODIGO = MEDICO.ESTATUS
                                    AND VAL_LOG = V_T);
    Begin
      OPEN F;
      FETCH F
        INTO f_codigo, FONOS_ROW.NOM_AFI;
      IF F%NOTFOUND THEN
        p_outnum1 := 1;
      ELSE
        p_outnum1 := 0;
        UPDATE INFOX_SESSION
           SET med_tra = f_codigo
         WHERE NUMSESSION = P_NUMSESSION;
      END IF;
      CLOSE F;
    /**Exception
      when others then
        P_OUTNUM1 := 1;**/
    End;
  END;
  -- procedure valida pin del afiliado Y el codigo afiliado --
  -- 0->afiliado valido 1-> afiliado invalidao  2-> pin invalido--
  PROCEDURE P_VALIDATEPIN(p_name       IN VARCHAR2,
                          p_numsession IN NUMBER,
                          p_instr1     IN VARCHAR2,
                          p_instr2     IN VARCHAR2,
                          p_innum1     IN NUMBER,
                          p_innum2     IN NUMBER,
                          p_outstr1    OUT VARCHAR2,
                          p_outstr2    OUT VARCHAR2,
                          p_outnum1    OUT NUMBER,
                          p_outnum2    OUT NUMBER) IS
  BEGIN
    DECLARE
      fecha_dia DATE; /* Variable que almacena la Fecha del Dia. */
      --DUMMY     VARCHAR2(1);
      FONOS_ROW INFOX_SESSION%ROWTYPE;
      --CONT      NUMBER(2);
      VAR_CODE NUMBER(1) := 1;
      --
      VAR_COD_ERR Number := Null;  --Varible para manejar el codigo de error que se interpretara en la emergencia por el monto Miguel A. Carrion FCCM 15/10/2021
      --
      CURSOR B IS
        SELECT TIP_AFI, '' CAT_N_MED
          FROM FONOS_PIN_AFILIADO
         WHERE AFILIADO = p_instr1
           AND PIN = p_instr2;
      CURSOR E IS
        SELECT SUBSTR(NO_MEDICO.NOMBRE, 1, 59)
          FROM NO_MEDICO NO_MEDICO
         WHERE NO_MEDICO.CODIGO = p_instr1
           AND FECHA_DIA >= TRUNC(FEC_ING)
           AND NO_MEDICO.ESTATUS =
               (SELECT CODIGO
                  FROM ESTATUS
                 WHERE CODIGO = NO_MEDICO.ESTATUS
                   AND VAL_LOG = V_T);

      CURSOR F IS
        SELECT 'DR. ' || MEDICO.PRI_NOM || ' ' || MEDICO.PRI_APE
          FROM MEDICO MEDICO
         WHERE MEDICO.CODIGO = p_instr1
           AND FECHA_DIA >= TRUNC(FEC_ING)
           AND MEDICO.ESTATUS = (SELECT CODIGO
                                   FROM ESTATUS
                                  WHERE CODIGO = MEDICO.ESTATUS
                                    AND VAL_LOG = V_T);

    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      fecha_dia := TO_DATE(TO_CHAR(SYSDATE, 'dd/mm/yyyy'), 'dd/mm/yyyy');
      OPEN B;
      FETCH B
        INTO FONOS_ROW.TIP_REC, FONOS_ROW.CAT_N_MED;
      IF B%FOUND THEN
        IF FONOS_ROW.TIP_REC = 'MEDICO' THEN
          OPEN F;
          FETCH F
            INTO FONOS_ROW.NOM_AFI;
          IF F%NOTFOUND THEN
            VAR_CODE := 1;
          ELSE
            VAR_CODE := 0;
          END IF;
          CLOSE F;
        ELSE
          OPEN E;
          FETCH E
            INTO FONOS_ROW.NOM_AFI;
          IF E%NOTFOUND THEN
            VAR_CODE := 1;
          ELSE
            VAR_CODE := 0;
          END IF;
          CLOSE E;
        END IF;
      ELSE
        VAR_CODE := 2;
      END IF;
      CLOSE B;
      p_outnum1 := VAR_CODE;
      UPDATE INFOX_SESSION
         SET TIP_REC   = FONOS_ROW.TIP_REC,
             NOM_AFI   = FONOS_ROW.NOM_AFI,
             CAT_N_MED = FONOS_ROW.CAT_N_MED,
             AFILIADO  = substr(P_INSTR1, 1, 16),
             PIN       = substr(P_INSTR2, 1, 10)
       WHERE NUMSESSION = P_NUMSESSION;
    /*EXCEPTION
      WHEN OTHERS THEN
        VAR_CODE  := 1;
        P_OUTNUM1 := VAR_CODE;*/
    END;
  END;
  --
  -- procedure valida asegurado --
  -- 0-> valido 1->  invalida 2-> no vigente --
  PROCEDURE P_VALIDATEASEGURADO(p_name       IN VARCHAR2,
                                p_numsession IN NUMBER,
                                p_instr1     IN VARCHAR2,
                                p_instr2     IN VARCHAR2,
                                p_innum1     IN NUMBER,
                                p_innum2     IN NUMBER,
                                p_outstr1    OUT VARCHAR2,
                                p_outstr2    OUT VARCHAR2,
                                p_outnum1    OUT NUMBER,
                                p_outnum2    OUT NUMBER) IS
  BEGIN
    /* @% Verificar Asegurado  */
    /* Nombre de la Funcion :  Validar Asegurado */
    /* Descripcion : Valida que el Asegurado sea valido */
    /* Descripcion : Valida que el Asegurado sea valido y actualia :*/
    /* code=1 si es valido y code=2 si no es valido, ademas de completar los  */
    /* datos de la poliza y asegurado  */
    DECLARE
      fecha_dia DATE; /* Variable que almacena la Fecha del Dia. */
      DUMMY     VARCHAR2(1);
      FONOS_ROW INFOX_SESSION%ROWTYPE;
      COD_ASE         NUMBER(11);
      COD_DEP         NUMBER(3);
      VAR_CODE        NUMBER(1) := 1;
      vTIP_ASE        VARCHAR2(10);
      V_PSS           NUMBER;
      v_error_handler varchar2(500);
      VAR_DEDUCIBLE_1 NUMBER;
      V_ACUM_REC_G    NUMBER;
      V_valida_limite NUMBER;
      V_RESERVA       NUMBER;
      V_VAR_IND_DED_1 VARCHAR2(10) := 'S';
      VAR_FEC_INI     POLIZA.FEC_INI%TYPE;
      vafiliado_sal   ASEGURADO.CODIGO%TYPE;
      --
      v_datos_asegurados varchar2(20);
      --
      V_Secuencial_precert  number;

      --
      CURSOR B IS
        SELECT TIP_REC, AFILIADO
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION;
      --
      VAR1 B%ROWTYPE;
      --
      CURSOR F IS
        SELECT TIP_N_MED FROM NO_MEDICO WHERE CODIGO = VAR1.AFILIADO;
      --
      VAR2 F%ROWTYPE;
      --
      CURSOR PLAN_MEDICINA(P_COMPANIA   NUMBER,
                           P_RAMO       NUMBER,
                           P_SECUENCIAL NUMBER,
                           P_PLAN       NUMBER) IS
        SELECT '1'
          FROM POL_C_SAL A
         WHERE A.COMPANIA = P_COMPANIA
           AND A.RAMO = P_RAMO
           AND A.SECUENCIAL = P_SECUENCIAL
           AND A.PLAN = P_PLAN
           AND A.COBERTURA = V_1166 --*--
           AND A.SERVICIO = V_1
           AND A.ESTATUS = V_40;

      ------------------------------------------------------
      --------- AGREGADO PARA BUSCAR EL DEDUCIBLE PRIMERO -- agregado por Leonardo febrero 2019
      ------------------------------------------------------
      CURSOR C IS
        SELECT POLIZA15.FEC_INI
          FROM POLIZA POLIZA15
         WHERE POLIZA15.COMPANIA = FONOS_ROW.COMPANIA
           AND POLIZA15.RAMO = FONOS_ROW.RAMO
           AND POLIZA15.SECUENCIAL = FONOS_ROW.SECUENCIAL
           AND POLIZA15.FEC_VER =
               (SELECT MAX(FEC_VER)
                  FROM POLIZA POLIZA2
                 WHERE POLIZA2.COMPANIA = POLIZA15.COMPANIA
                   AND POLIZA2.RAMO = POLIZA15.RAMO
                   AND POLIZA2.SECUENCIAL = POLIZA15.SECUENCIAL
                      --AND TRUNC(POLIZA2.FEC_VER) <= FECHA_DIA);
                   AND POLIZA2.FEC_VER < TRUNC(FECHA_DIA) + V_1);

      --------------------------------------------------------------------------------------------------
      --- CURSOR QUE BUSCA LOS PLANES DE UN AFILIADO, PARA UTILIZARLO EN CASO DE EL PLAN INTERNACIONAL
      --- AUN TENGA DEDUCIBLE PENDIENTE. -- agregado por Leonardo febrero 2019
      --------------------------------------------------------------------------------------------------
      CURSOR C_BUSCA_PLAN_ALTERNATIVO_ASE IS
        SELECT RAMO, SECUENCIAL, PLAN
          FROM ASE_POL02_V
         WHERE ASEGURADO = COD_ASE
           AND ESTATUS = V_7 -- VIGENTE
           AND PLAN != TO_NUMBER(FONOS_ROW.PLAN);

      CURSOR C_BUSCA_PLAN_ALTERNATIVO_DEP IS
        SELECT RAMO, SECUENCIAL, PLAN
          FROM DEP_POL02_V
         WHERE ASEGURADO = COD_ASE
           AND DEPENDIENTE = NVL(COD_DEP, 0)
           AND ESTATUS = V_25 -- VIGENTE
           AND PLAN != TO_NUMBER(FONOS_ROW.PLAN);

    --Miguel A. Carrion 29/06/2020
     Cursor C_Busca_Nss_ASE
         Is
      Select Nss
        From asegurado a
      Where a.codigo = COD_ASE ;

     Cursor C_Busca_Nss_Dep
        is
      Select nss
          From dependiente
        Where asegurado = COD_ASE
          And secuencia = NVL(COD_DEP, 0);

      V_RAMO_ALTERNATIVO       POLIZA.RAMO%TYPE;
      V_SECUENCIAL_ALTERNATIVO POLIZA.SECUENCIAL%TYPE;
      V_PLAN_ALTERNATIVO       PLAN.CODIGO%TYPE;
      v_CARNET                 VARCHAR(20);
    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      fecha_dia := TRUNC(SYSDATE);
      OPEN B;
      FETCH B
        INTO VAR1;
      IF B%FOUND THEN
        IF VAR1.TIP_REC = 'NO_MEDICO' THEN
          OPEN F;
          FETCH F
            INTO VAR2;
          IF F%FOUND THEN
            V_PSS := VAR2.TIP_N_MED;
          END IF;
          CLOSE F;
        ELSE
          V_PSS := 0;
        END IF;
      ELSE
        V_PSS := 0;
      END IF;
      CLOSE B;
      --
     --Nueva forma de buscar si el canet existe o si esta activo.

        P_BUSCA_AFILIADO_NUM_PLAS(P_INSTR1, COD_ASE, COD_DEP, vTIP_ASE, VAR_CODE);





         ---Proceso para cancelar los reclamos Transitorio de un afiliado ante de realizar el reclamo

        --@ENFOCO Jose De Leon
        Begin

        P_Canc_Statu_Ini_Afiliado (P_INSTR1);



        End;




      V_plasticos := P_INSTR1; --Miguel A. Carrion 06/09/2021
      -- ****************************************************

        IF NVL(COD_DEP, 0) = 0 THEN
          vTIP_ASE := 'ASEGURADO';
          --
           Open C_Busca_Nss_ASE;
           Fetch C_Busca_Nss_ASE Into V_nss;
           Close C_Busca_Nss_ASE;
          --
        ELSE
          vTIP_ASE := 'DEPENDIENT';

        --</84770>
           Open C_Busca_Nss_Dep;
           Fetch C_Busca_Nss_Dep Into V_nss;
           Close C_Busca_Nss_Dep;
          --
        END IF;
        --

      -- ****************************************************
      IF VAR_CODE = 0
          THEN

          VALIDA_AFILIADO_SERVICIO(vTIP_ASE,
                                   V_PSS,
                                   COD_ASE,
                                   COD_DEP,
                                   '',
                                   FONOS_ROW.COMPANIA,
                                   FONOS_ROW.RAMO,
                                   FONOS_ROW.SECUENCIAL,
                                   FONOS_ROW.PLAN,
                                   FONOS_ROW.CATEGORIA,
                                   FONOS_ROW.NOM_ASE,
                                   FONOS_ROW.FEC_NAC,
                                   FONOS_ROW.FEC_ING,
                                   FONOS_ROW.SEXO,
                                   FONOS_ROW.EST_CIV,
                                   VAR_CODE);


           DBMS_OUTPUT.PUT_LINE('VAR_CODE:  '||VAR_CODE);
          --

        --
        ---------------------------------------------------------------------------------
        ----- //////// busca deducible primero -- agregado por Leonardo febrero 2019
        ---------------------------------------------------------------------------------
        OPEN C;
        FETCH C
          INTO VAR_FEC_INI;
        CLOSE C;
        --
        DBMS_OUTPUT.PUT_LINE('vafiliado_sal:  '||vafiliado_sal);

        /****vafiliado_sal := DBAPER.PAQ_SYNC_RECLAMACION.F_BUSCA_ASEGURADO(COD_ASE,
                                                                       COD_DEP,
                                                                       FONOS_ROW.COMPANIA,
                                                                       FONOS_ROW.RAMO,
                                                                       FONOS_ROW.SECUENCIAL,
                                                                       vTIP_ASE);*******/

           DBMS_OUTPUT.PUT_LINE('vafiliado_sal:  '||vafiliado_sal);
        -- Si no existe en Saludcore, el asegurado/poliza pertenece al Salud Internaconal de Infoplan.
        -- GM | ENFOCO 13/11/2019
       /***** IF (vafiliado_sal IS NULL OR vafiliado_sal = 0) THEN
          vafiliado_sal := DBAPER.PAQ_RECLAMACION_SI.F_ASE_DEP_CODIGO(COD_ASE,
                                                                      COD_DEP,
                                                                      FONOS_ROW.COMPANIA,
                                                                      FONOS_ROW.RAMO,
                                                                      FONOS_ROW.SECUENCIAL);
              DBMS_OUTPUT.PUT_LINE('vafiliado_sal_2:  '||vafiliado_sal);
        END IF;********/
        --
        v_error_handler := dbaper.PAQ_RECLAMACION_SI.F_OBT_DATOS_DED(1,
                                                                     NULL, --V_MON_MAX                            ,
                                                                     NULL, --V_DIAS_TIP_COB                       ,
                                                                     NULL, --V_MON_DISP_TC                        ,
                                                                     NULL, --NO_M_COB_ROW.LIMITE  BUSCAR                ,
                                                                     NULL, --var_frecuencia                       ,
                                                                     NULL, --fonos_row.TIP_COB                    ,
                                                                     NULL, --fonos_row.SECUENCIAL                 ,
                                                                     fonos_row.ramo,
                                                                     fonos_row.compania,
                                                                     TO_CHAR(SYSDATE, 'YYYY'), --fonos_row.ANO_rec                    ,
                                                                     'N', --'A'                                  ,
                                                                     'N', --'A'                                  ,
                                                                     V_VAR_IND_DED_1,
                                                                     fonos_row.secuencial,
                                                                     fonos_row.plan,
                                                                     vafiliado_sal,
                                                                     vTIP_ASE, --var_tip_a_uso                        ,
                                                                     fecha_dia,
                                                                     'L',
                                                                     'P',
                                                                     NULL, --V_APL_DED_RIE                        ,
                                                                     NULL, --V_IND_DED_RIE                        ,
                                                                     NULL, --VAR_FEC_INI                          ,
                                                                     NULL, --DSP_FEC_ING                          ,
                                                                     1, --fonos_row.tip_ser                    ,
                                                                     NULL, --fonos_row.COBERTURA                  ,
                                                                     'S',
                                                                     NULL, --V_FEC_I_CAR                          ,
                                                                     NULL, --V_FEC_F_CAR                          ,
                                                                     'N', --V_IND_DED_CAS  BUSCAR                       ,
                                                                     NULL, --V_NUMERO_CASO                        ,
                                                                     VAR_DEDUCIBLE_1,
                                                                     fonos_row.mon_rec,
                                                                     V_ACUM_REC_G,
                                                                     fonos_row.mon_rec,
                                                                     fonos_row.mon_rec,
                                                                     v_RESERVA,
                                                                     V_valida_limite,
                                                                     0);

         DBMS_OUTPUT.PUT_LINE('v_error_handler:  '||v_error_handler);

        ---------------------------------------------------------------------------------
        ----- //////// busca deducible primero -- agregado por Leonardo febrero 2019
        ---------------------------------------------------------------------------------
        V_DEDUCIBLE_MIREX := 0;
        V_DEDUCIBLE_MIREX := VAR_DEDUCIBLE_1;
        ---
        V_RAMO_ALTERNATIVO       := NULL;
        V_SECUENCIAL_ALTERNATIVO := NULL;
        V_PLAN_ALTERNATIVO       := NULL;
        ---
        IF V_DEDUCIBLE_MIREX > 0 THEN
          IF NVL(COD_DEP, 0) = 0 THEN
            OPEN C_BUSCA_PLAN_ALTERNATIVO_ASE;
            FETCH C_BUSCA_PLAN_ALTERNATIVO_ASE
              INTO V_RAMO_ALTERNATIVO,
                   V_SECUENCIAL_ALTERNATIVO,
                   V_PLAN_ALTERNATIVO;
            CLOSE C_BUSCA_PLAN_ALTERNATIVO_ASE;
          ELSE
            OPEN C_BUSCA_PLAN_ALTERNATIVO_DEP;
            FETCH C_BUSCA_PLAN_ALTERNATIVO_DEP
              INTO V_RAMO_ALTERNATIVO,
                   V_SECUENCIAL_ALTERNATIVO,
                   V_PLAN_ALTERNATIVO;
            CLOSE C_BUSCA_PLAN_ALTERNATIVO_DEP;
          END IF;
        END IF;
        ---
        IF V_RAMO_ALTERNATIVO IS NOT NULL THEN
          FONOS_ROW.RAMO       := V_RAMO_ALTERNATIVO;
          FONOS_ROW.SECUENCIAL := V_SECUENCIAL_ALTERNATIVO;
          FONOS_ROW.PLAN       := V_PLAN_ALTERNATIVO;
          V_DEDUCIBLE_MIREX    := 0;
        END IF;

      ELSE
        P_OUTNUM1 := VAR_CODE;
      END IF;
      --
      UPDATE INFOX_SESSION
         SET CODE        = VAR_CODE,
             COMPANIA    = FONOS_ROW.COMPANIA,
             RAMO        = FONOS_ROW.RAMO,
             SECUENCIAL  = FONOS_ROW.SECUENCIAL,
             PLAN        = FONOS_ROW.PLAN,
             SEXO        = FONOS_ROW.SEXO,
             FEC_ING     = FONOS_ROW.FEC_ING,
             FEC_NAC     = FONOS_ROW.FEC_NAC,
             EST_CIV     = FONOS_ROW.EST_CIV,
             CATEGORIA   = FONOS_ROW.CATEGORIA,
             NOM_ASE     = FONOS_ROW.NOM_ASE,
             ASEGURADO   = COD_ASE,
             DEPENDIENTE = COD_DEP,
             ASE_CARNET  = P_INSTR1
       WHERE NUMSESSION = P_NUMSESSION;
      --
       --
      P_OUTNUM1 := VAR_CODE;
      --
      --
      OPEN PLAN_MEDICINA(FONOS_ROW.COMPANIA,
                         FONOS_ROW.RAMO,
                         FONOS_ROW.SECUENCIAL,
                         FONOS_ROW.PLAN);
      FETCH PLAN_MEDICINA
        INTO DUMMY;
      --
      IF PLAN_MEDICINA%FOUND THEN
        P_OUTNUM2 := FONOS_ROW.PLAN;
      ELSE
        P_OUTNUM2 := 230;
      END IF;
      CLOSE PLAN_MEDICINA;
      --

    END;
  END;
  --

  -- procedure valida asegurado LOCAL--
  -- 0-> valido 1->  invalida 2-> no vigente --
  PROCEDURE P_VALIDATEASEGURADO_LOC(p_name       IN VARCHAR2,
                                    p_numsession IN NUMBER,
                                    p_instr1     IN VARCHAR2,
                                    p_instr2     IN VARCHAR2,
                                    p_innum1     IN NUMBER,
                                    p_innum2     IN NUMBER,
                                    p_outstr1    OUT VARCHAR2,
                                    p_outstr2    OUT VARCHAR2,
                                    p_outnum1    OUT NUMBER,
                                    p_outnum2    OUT NUMBER) IS

  BEGIN
    /* @% Verificar Asegurado  */
    /* Nombre de la Funcion :  Validar Asegurado */
    /* Descripcion : Valida que el Asegurado sea valido */
    /* Descripcion : Valida que el Asegurado sea valido y actualia :*/
    /* code=1 si es valido y code=2 si no es valido, ademas de completar los  */
    /* datos de la poliza y asegurado  */
    DECLARE
      DUMMY     VARCHAR2(1);
      FONOS_ROW INFOX_SESSION%ROWTYPE;
      COD_ASE   NUMBER(11);
      COD_DEP   NUMBER(3);
      VAR_CODE  NUMBER(1) := 1;
      vTIP_ASE  VARCHAR2(10);
      V_PSS     NUMBER;
      v_CARNET  VARCHAR(20);
      --

      --
      CURSOR B IS
        SELECT TIP_REC, AFILIADO
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION;
      --
      VAR1 B%ROWTYPE;
      --
      CURSOR F IS
        SELECT TIP_N_MED FROM NO_MEDICO WHERE CODIGO = VAR1.AFILIADO;
      --
      VAR2 F%ROWTYPE;
      --

      CURSOR PLAN_MEDICINA(P_COMPANIA   NUMBER,
                           P_RAMO       NUMBER,
                           P_SECUENCIAL NUMBER,
                           P_PLAN       NUMBER) IS
        SELECT '1'
          FROM POL_C_SAL A
         WHERE A.COMPANIA = P_COMPANIA
           AND A.RAMO = P_RAMO
           AND A.SECUENCIAL = P_SECUENCIAL
           AND A.PLAN = P_PLAN
           AND A.COBERTURA = V_1166
           AND A.SERVICIO = V_1
           AND A.ESTATUS = V_40;
    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      OPEN B;
      FETCH B
        INTO VAR1;
      IF B%FOUND THEN
        IF VAR1.TIP_REC = 'NO_MEDICO' THEN
          OPEN F;
          FETCH F
            INTO VAR2;
          IF F%FOUND THEN
            V_PSS := VAR2.TIP_N_MED;
          END IF;
          CLOSE F;
        ELSE
          V_PSS := 0;
        END IF;
      ELSE
        V_PSS := 0;
      END IF;
      CLOSE B;
      --
      -- Proceso que Busca los datos del afiliado por el Numero de Plastico
      -- GMa?on 14/09/2010

        P_BUSCA_AFILIADO_NUM_PLAS(P_INSTR1, COD_ASE, COD_DEP, vTIP_ASE, VAR_CODE);



         ---Proceso para cancelar los reclamos Transitorio de un afiliado ante de realizar el reclamo

        --@ENFOCO Jose De Leon
        Begin

        P_Canc_Statu_Ini_Afiliado (P_INSTR1);



        End;


          IF VAR_CODE = 0
             THEN

          VALIDA_AFILIADO_SERVICIO_LOC(vTIP_ASE,
                                       V_PSS,
                                       COD_ASE,
                                       COD_DEP,
                                       '',
                                       FONOS_ROW.COMPANIA,
                                       FONOS_ROW.RAMO,
                                       FONOS_ROW.SECUENCIAL,
                                       FONOS_ROW.PLAN,
                                       FONOS_ROW.CATEGORIA,
                                       FONOS_ROW.NOM_ASE,
                                       FONOS_ROW.FEC_NAC,
                                       FONOS_ROW.FEC_ING,
                                       FONOS_ROW.SEXO,
                                       FONOS_ROW.EST_CIV,
                                       VAR_CODE);
          --

        --
      ELSE
        P_OUTNUM1 := VAR_CODE;
      END IF;
      --
      UPDATE INFOX_SESSION
         SET CODE        = VAR_CODE,
             COMPANIA    = FONOS_ROW.COMPANIA,
             RAMO        = FONOS_ROW.RAMO,
             SECUENCIAL  = FONOS_ROW.SECUENCIAL,
             PLAN        = FONOS_ROW.PLAN,
             SEXO        = FONOS_ROW.SEXO,
             FEC_ING     = FONOS_ROW.FEC_ING,
             FEC_NAC     = FONOS_ROW.FEC_NAC,
             EST_CIV     = FONOS_ROW.EST_CIV,
             CATEGORIA   = FONOS_ROW.CATEGORIA,
             NOM_ASE     = FONOS_ROW.NOM_ASE,
             ASEGURADO   = COD_ASE,
             DEPENDIENTE = COD_DEP,
             ASE_CARNET  = P_INSTR1
       WHERE NUMSESSION = P_NUMSESSION;
      --
      P_OUTNUM1 := VAR_CODE;
      --
      OPEN PLAN_MEDICINA(FONOS_ROW.COMPANIA,
                         FONOS_ROW.RAMO,
                         FONOS_ROW.SECUENCIAL,
                         FONOS_ROW.PLAN);
      FETCH PLAN_MEDICINA
        INTO DUMMY;
      --
      IF PLAN_MEDICINA%FOUND THEN
        P_OUTNUM2 := FONOS_ROW.PLAN;
      ELSE
        P_OUTNUM2 := 230;
      END IF;
      CLOSE PLAN_MEDICINA;
      --
    /*EXCEPTION
      WHEN OTHERS THEN
        VAR_CODE  := 4;
        P_OUTNUM1 := VAR_CODE;*/
    END;
  END;
  -- procedure valida que la reclamacion exista Y que sea del afiliado --
  -- 0-> valido 1-> invalido --
  PROCEDURE P_VALIDATERECLAMACION(p_name       IN VARCHAR2,
                                  p_numsession IN NUMBER,
                                  p_instr1     IN VARCHAR2,
                                  p_instr2     IN VARCHAR2,
                                  p_innum1     IN NUMBER,
                                  p_innum2     IN NUMBER,
                                  p_outstr1    OUT VARCHAR2,
                                  p_outstr2    OUT VARCHAR2,
                                  p_outnum1    OUT NUMBER,
                                  p_outnum2    OUT NUMBER) IS
  BEGIN
    /* @% Buscar Reclamacion */
    /* Descripcion : Busca datos de una reclamacion */
    DECLARE
      REC_ROW     RECLAMACION%ROWTYPE;
      FONOS_ROW   INFOX_SESSION%ROWTYPE;
      REC_COB_ROW REC_C_SAL%ROWTYPE;
      VAR_CODE    NUMBER(1) := 1;
      FECHA_DIA   DATE;
      ANO_REC     NUMBER(4);

      CURSOR A IS
        SELECT ANO_REC,
               COMPANIA,
               RAMO,
               TO_NUMBER(substr(P_INSTR1, 1, 15)) SEC_REC,
               TIP_REC,
               AFILIADO,
               SECUENCIAL,
               RECLAMACION,
               TO_NUMBER(ASEGURADO) ASEGURADO,
               TO_NUMBER(DEPENDIENTE) DEPENDIENTE
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION
           FOR UPDATE;

      CURSOR B IS
        SELECT A.ANO,
               A.COMPANIA,
               A.RAMO,
               A.SECUENCIAL,
               A.ASE_USO,
               A.DEP_USO,
               A.FEC_TRA
          FROM RECLAMACION A
         WHERE A.ASE_USO = FONOS_ROW.ASEGURADO
              --AND NVL(A.DEP_USO, 0) = FONOS_ROW.DEPENDIENTE
           AND (A.DEP_USO = nvl(FONOS_ROW.DEPENDIENTE, 0) OR
               A.DEP_USO IS NULL and NVL(FONOS_ROW.DEPENDIENTE, 0) = 0)
           AND A.ANO = ANO_REC
           AND A.COMPANIA = FONOS_ROW.COMPANIA
           AND A.RAMO = FONOS_ROW.RAMO
           AND A.SECUENCIAL = FONOS_ROW.SEC_REC
           AND A.TIP_REC = FONOS_ROW.TIP_REC
           AND A.RECLAMANTE = FONOS_ROW.AFILIADO
              --    AND TRUNC(A.FEC_APE) = TRUNC(FECHA_DIA)
           AND A.ESTATUS = (SELECT E.CODIGO
                              FROM ESTATUS E
                             WHERE E.CODIGO = A.ESTATUS
                               AND VAL_LOG = V_T);
      CURSOR C IS
        SELECT SUM(NVL(MON_PAG, 0))
          FROM REC_C_SAL
         WHERE ANO = REC_ROW.ANO
           AND COMPANIA = REC_ROW.COMPANIA
           AND RAMO = REC_ROW.RAMO
           AND SECUENCIAL = REC_ROW.SECUENCIAL;
    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      FECHA_DIA := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      ANO_REC   := TO_NUMBER(SUBSTR(TO_CHAR(FECHA_DIA, 'DD/MM/YYYY'), 7, 4));
      --
      OPEN A;
      FETCH A
        INTO FONOS_ROW.ANO_REC,
             FONOS_ROW.COMPANIA,
             FONOS_ROW.RAMO,
             FONOS_ROW.SEC_REC,
             FONOS_ROW.TIP_REC,
             FONOS_ROW.AFILIADO,
             FONOS_ROW.SECUENCIAL,
             FONOS_ROW.RECLAMACION,
             FONOS_ROW.ASEGURADO,
             FONOS_ROW.DEPENDIENTE;
      IF A%FOUND THEN
        OPEN B;
        FETCH B
          INTO REC_ROW.ANO,
               REC_ROW.COMPANIA,
               REC_ROW.RAMO,
               REC_ROW.SECUENCIAL,
               REC_ROW.ASE_USO,
               REC_ROW.DEP_USO,
               REC_ROW.FEC_TRA;

        IF B%FOUND THEN
          FONOS_ROW.ASEGURADO   := REC_ROW.ASE_USO;
          FONOS_ROW.DEPENDIENTE := REC_ROW.DEP_USO;
          --
          OPEN C;
          FETCH C
            INTO REC_COB_ROW.MON_PAG;
          IF C%FOUND THEN
            UPDATE INFOX_SESSION
               SET CODE        = 0,
                   ANO_REC     = REC_ROW.ANO,
                   COMPANIA    = REC_ROW.COMPANIA,
                   RAMO        = REC_ROW.RAMO,
                   SEC_REC     = REC_ROW.SECUENCIAL,
                   SECUENCIAL  = FONOS_ROW.SECUENCIAL,
                   ASEGURADO   = FONOS_ROW.ASEGURADO,
                   DEPENDIENTE = FONOS_ROW.DEPENDIENTE,
                   MON_REC     = REC_COB_ROW.MON_PAG,
                   FEC_APE     = REC_ROW.FEC_TRA,
                   RECLAMACION = FONOS_ROW.RECLAMACION
             WHERE CURRENT OF A;
            VAR_CODE := 0;
          END IF;
          CLOSE C;
        ELSE
          UPDATE INFOX_SESSION SET CODE = 1 WHERE CURRENT OF A;
          VAR_CODE := 1;
        END IF;
      END IF;
      CLOSE A;
      CLOSE B;
      P_OUTNUM1 := VAR_CODE;
    END;
  END;
  --
  -- procedure retorna los montos que se pagan por la cobertura --
  -- 0->VALIDA 1-> INVALIDA 2-> ASEGURADO NO LA TIENE DISPONIBLE 3-> AFILIADO NO LA PUEDE OFRECER--
  PROCEDURE P_VALIDATECOBERTURA(P_NAME IN VARCHAR2,

    P_NUMSESSION IN NUMBER,

    P_INSTR1 IN VARCHAR2,

    P_INSTR2 IN VARCHAR2,

    P_INNUM1 IN NUMBER,

    P_INNUM2 IN NUMBER,

    P_OUTSTR1 OUT VARCHAR2,

    P_OUTSTR2 OUT VARCHAR2,

    P_OUTNUM1 OUT NUMBER,

    P_OUTNUM2 OUT NUMBER) IS

    V_PSS_NO_CAMBIA_COVID NUMBER;

    BEGIN
    /* @% Verificar Disponibilidad de Cobertura */
    /* Descripcion : Valida que el Afiliado  pueda ofrecer la cobertura y que el asegurado*/
    /*               pueda recibir la cobertura. */
      DECLARE
        DUMMY                VARCHAR2(1);
        ERROR                CHAR(1);
        ERROR1               BOOLEAN; /*  Se utiliza igual que ERROR, pero es enviada en algunos casos que la funcion devuelve boolean */
        RED_EXCEPCION_ODON   BOOLEAN;
        CAT_PLAN_ODON        BOOLEAN;
        VAR_CODE             NUMBER(2) := 1;
    --
        VAR_COD_ERR          NUMBER := NULL; --Varible para manejar el codigo de error que se interpretara en la emergencia por el monto Miguel A. Carrion FCCM 15/10/2021
    --
        FONOS_ROW            INFOX_SESSION%ROWTYPE;
        SER_SAL_ROW          SER_SAL%ROWTYPE;
        TIP_C_SAL_ROW        TIP_C_SAL%ROWTYPE;
        COB_SAL_ROW          COB_SAL%ROWTYPE;
        NO_M_COB_ROW         NO_M_COB%ROWTYPE;
        DES_TIP_N_MED        TIPO_NO_MEDICO.DESCRIPCION%TYPE;
        COD_ASE              NUMBER(11);
        COD_DEP              NUMBER(3);
        VAR_TIP_SER2         SER_SAL.CODIGO%TYPE;
        FECHA_DIA            DATE;
        POR_COA              POL_P_SER.POR_COA%TYPE;
        PLA_STC_ROW          PLA_STC%ROWTYPE;
        VAR_ESTATUS_CAN      RECLAMACION.ESTATUS%TYPE := 183;
        VAR_TIP_A_USO        RECLAMACION.TIP_A_USO%TYPE;
        VAR_FEC_INI          POLIZA.FEC_INI%TYPE;
        VAR_FEC_FIN          POLIZA.FEC_FIN%TYPE;
        T_FEC_INI            POLIZA.FEC_INI%TYPE;
        T_FEC_FIN            POLIZA.FEC_FIN%TYPE;
        DSP_COB_LAB          NUMBER;
        DSP_FREC_TIP_COB     NUMBER;
        DSP_FREC_ACUM        NUMBER;
        DSP_MON_PAG_ACUM     NUMBER;
        SEC_RECLAMACION      RECLAMACION.SECUENCIAL%TYPE;
        MONTO_CONTRATADO     VARCHAR(1);
    /* Parametro para saber si la cobertura esta contratada con  */
    /* el reclamante o con la poliza (ej. habitacion y medicina) */
        MONTO_LABORATORIO    NUMBER(11, 2);
        VAR_CATEGORIA        VARCHAR2(40);
        P_DSP_CATEGORIA      PLA_STC.CATEGORIA%TYPE;
        P_DSP_EST_CIV        PLA_STC.EST_CIV%TYPE;
        LIMITE_LABORATORIO   LIM_C_REC.MON_MAX%TYPE;
        P_MON_EXE            LIM_C_REC.MON_E_COA%TYPE;
        P_UNI_T_EXE          LIM_C_REC.UNI_TIE_E%TYPE;
        P_UNI_T_MAX          LIM_C_REC.UNI_TIE_M%TYPE;
        P_RAN_EXE            LIM_C_REC.RAN_U_EXC%TYPE;
        P_POR_COA            LIM_C_REC.POR_COA%TYPE;
        P_MON_ACUM           NUMBER(14, 2);
        ORI_FLAG             VARCHAR2(1);
        V_INSER              NUMBER(2);
        V_INTIP              NUMBER(3);
        V_INCOB              VARCHAR2(10);
        P_MONTO_MAX          NUMBER(11, 2);
        VAR_FRECUENCIA       PLA_STC_ROW.FRECUENCIA%TYPE;
        VAR_UNI_TIE_F        PLA_STC_ROW.UNI_TIE_F%TYPE;
        VAR_DSP_FREC_ACUM    DSP_FREC_ACUM%TYPE;
        V_PARAM              TPARAGEN.VALPARAM%TYPE := F_OBTEN_PARAMETRO_SEUS('PLA_SAL_INT');
        V_INTERNACIONAL      VARCHAR2(1);
        V_MSG                VARCHAR2(100);
        V_RED_PLAT           NUMBER(3);
        P_RAN_U_EXC          LIM_C_REC.RAN_U_EXC%TYPE;
        P_RAN_U_MAX          LIM_C_REC.RAN_U_EXC%TYPE;
    -- Technocons
        MFRAUDE              VARCHAR(1);
        VMON_MAX_COB_ORIGEN  NUMBER(11, 2);
        M_PLAN_EXCEPTION     VARCHAR2(4000);
        M_VALIDA_PLAN        VARCHAR2(4000); --
    --<jdeveaux 18may2016>
    --Variables para capturar los datos de la poliza original de plan voluntario cambia a la poliza del plan basico
        V_PLAN_ORI           NUMBER(3);
        V_COMPANIA_ORI       NUMBER(2);
        V_RAMO_ORI           NUMBER(2);
        V_SEC_ORI            NUMBER(7);
    --</jdeveaux>
        VESTUDIO_REPETICION  VARCHAR2(1) := 'N';
    --Enfoco mcarrion 12/02/2019
        V_PROV_CAPITADO      NUMBER(1) := 0;
        V_PROV_BASICO        NUMBER;
        V_PROV_EXISTE        NUMBER;
        V_NUEVO              VARCHAR2(1);
    --Enfoco mcarrion 12/02/2019
    --
        V_SECUENCIAL_PRECERT NUMBER;
    --
        V_SERV_EME           NUMBER;
        CURSOR C_PLAN_EXCEPTION IS
          SELECT
            VALPARAM
          FROM
            TPARAGEN D
          WHERE
            NOMPARAM IN ('LIB_PLAN_FONO')
            AND COMPANIA = FONOS_ROW.COMPANIA;
        CURSOR C_VALIDA_PLAN_EXCENTO(MPLAN VARCHAR2, M_LISTA_PLAN VARCHAR2) IS
          SELECT
            COLUMN_VALUE
          FROM
            TABLE(SPLIT(M_LISTA_PLAN))
          WHERE
            COLUMN_VALUE = MPLAN;
        CURSOR A IS
          SELECT
            TIP_REC,
            AFILIADO,
            TIP_COB,
            COBERTURA,
            COMPANIA,
            RAMO,
            SECUENCIAL,
            PLAN,
            ASEGURADO,
            DEPENDIENTE,
            SEXO,
            FEC_ING,
            FEC_NAC,
            ANO_REC,
            SEC_REC,
            CATEGORIA,
            EST_CIV,
            MON_REC_AFI,
            CAT_N_MED,
            TIP_SER
          FROM
            INFOX_SESSION
          WHERE
            NUMSESSION = P_NUMSESSION FOR UPDATE;
        CURSOR B IS
          SELECT
            TIP_N_MED.DESCRIPCION
          FROM
            NO_MEDICO,
            TIPO_NO_MEDICO TIP_N_MED
          WHERE
            NO_MEDICO.CODIGO = FONOS_ROW.AFILIADO
            AND TIP_N_MED.CODIGO = NO_MEDICO.TIP_N_MED;
        CURSOR C IS
          SELECT
            POLIZA15.FEC_INI,
            POLIZA15.FEC_FIN
          FROM
            POLIZA POLIZA15
          WHERE
            POLIZA15.COMPANIA = FONOS_ROW.COMPANIA
            AND POLIZA15.RAMO = FONOS_ROW.RAMO
            AND POLIZA15.SECUENCIAL = FONOS_ROW.SECUENCIAL
            AND POLIZA15.FEC_VER = (
              SELECT
                MAX(FEC_VER)
              FROM
                POLIZA POLIZA2
              WHERE
                POLIZA2.COMPANIA = POLIZA15.COMPANIA
                AND POLIZA2.RAMO = POLIZA15.RAMO
                AND POLIZA2.SECUENCIAL = POLIZA15.SECUENCIAL
    --AND TRUNC(POLIZA2.FEC_VER) <= FECHA_DIA); --*--
                AND POLIZA2.FEC_VER < TRUNC(FECHA_DIA) + V_1
            );
        CURSOR D IS
          SELECT
            DESCRIPCION
          FROM
            CATEGORIA_ASEGURADO
          WHERE
            CODIGO = FONOS_ROW.CATEGORIA;
        CURSOR C_COBERTURA IS
          SELECT
            '1'
          FROM
            COB_SAL
          WHERE
            CODIGO = TO_NUMBER(FONOS_ROW.COBERTURA);
    -- Technocons * Victor Acevedo
        CURSOR C_FRAUDE IS
          SELECT
            FRAUDE
          FROM
            MOTIVO_ASE_DEP
          WHERE
            ASEGURADO = COD_ASE
            AND DEPENDIENTE = NVL(COD_DEP,
            0)
            AND FRAUDE = V_S;
    --
    --TP 09/11/2018 Enfoco
        CURSOR CAT_MEDICO(VRECLAMANTE NUMBER) IS
          SELECT
            CODIGO
          FROM
            MEDICO A
          WHERE
            CODIGO = VRECLAMANTE
            AND EXISTS (
              SELECT
                1
              FROM
                MED_ESP_V B
              WHERE
                A.CODIGO = B.MEDICO
                AND B.ESPECIALIDAD = V_229
            );
        CURSOR CAT_N_MED(VRECLAMANTE NUMBER) IS
          SELECT
            CODIGO
          FROM
            NO_MEDICO
          WHERE
            CODIGO = VRECLAMANTE
            AND TIP_N_MED = V_6;
        V_CAT                NUMBER;
    ---Enfoco mcarrion 12/02/2019
        CURSOR CUR_PROV_CAPITADO IS
          SELECT
            VALOR_CAPITA,
            AFILIADO
          FROM
            POLIZA_PROVEDOR P,
            NO_MEDICO N
          WHERE
            P.COMPANIA = FONOS_ROW.COMPANIA
            AND P.RAMO = FONOS_ROW.RAMO
            AND P.SECUENCIAL = FONOS_ROW.SECUENCIAL
            AND P.SERVICIO = FONOS_ROW.TIP_SER
            AND P.PLAN = FONOS_ROW.PLAN
            AND N.CODIGO = P.AFILIADO
            AND N.VALOR_CAPITA = V_1
            AND P.ESTATUS = V_46
            AND P.FEC_VER = (
              SELECT
                MAX(FEC_VER)
              FROM
                POLIZA_PROVEDOR A
              WHERE
                A.COMPANIA = P.COMPANIA
                AND A.RAMO = P.RAMO
                AND A.SECUENCIAL = P.SECUENCIAL
                AND A.PLAN = P.PLAN
                AND A.SERVICIO = P.SERVICIO
            );
        CURSOR CAP_BASICO(P_PROVEEDOR NUMBER) IS
          SELECT
            1
          FROM
            PLAN_AFILIADO
          WHERE
            PLAN = V_230 --*--
            AND AFILIADO = P_PROVEEDOR
            AND SERVICIO = V_8 --*--
            AND TIP_AFI IN (V_NO_MEDICO,
            V_MEDICO); --*--
        CURSOR NUEVO(VRECLAMANTE NUMBER) IS
          SELECT
            'S'
          FROM
            PLAN_DENTAL_NUEVO P
          WHERE
            P.TIP_AFI = V_NO_MEDICO --*--
            AND P.AFILIADO = VRECLAMANTE
            AND P.NUEVO = V_S;
        CURSOR CUR_CAT_PROV IS
          SELECT
            A.AFILIADO,
            A.CAT_PRO
          FROM
            POL_PRO A
          WHERE
            COMPANIA = FONOS_ROW.COMPANIA
            AND RAMO = FONOS_ROW.RAMO
            AND SECUENCIAL = FONOS_ROW.SECUENCIAL
            AND PLAN = FONOS_ROW.PLAN
            AND SERVICIO = FONOS_ROW.TIP_SER
            AND ESTATUS = V_46
            AND FEC_VER = (
              SELECT
                MAX(B.FEC_VER)
              FROM
                POLIZA_PROVEDOR B
              WHERE
                A.COMPANIA = B.COMPANIA
                AND A.RAMO = B.RAMO
                AND A.SECUENCIAL = B.SECUENCIAL
                AND A.PLAN = B.PLAN
                AND A.TIP_AFI = B.TIP_AFI
                AND A.AFILIADO = B.AFILIADO
                AND A.SERVICIO = B.SERVICIO
            );
        CURSOR C_PROVEEDOR (P_COMPANIA NUMBER, P_RAMO NUMBER, P_SEC_POL NUMBER, P_PLAN NUMBER, P_SERVICIO NUMBER) IS
          SELECT
            '1'
          FROM
            POLIZA_PROVEDOR P
          WHERE
            COMPANIA = P_COMPANIA
            AND RAMO = P_RAMO
            AND SECUENCIAL = P_SEC_POL
            AND PLAN = P_PLAN
            AND SERVICIO = P_SERVICIO;
        V_PROVEEDOR          NUMBER;
        V_CATEGORIA          NUMBER;
        V_COD_ERROR          NUMBER;
        CURSOR C_PSS_NO_CAMBIA_COVID (P_CODIGO_PSS NUMBER) IS
          SELECT
            1
          FROM
            PSS_NO_CAMBIA_COVID
          WHERE
            CODIGO_PSS = P_CODIGO_PSS;
        FUNCTION BUSCAR_DATOS_COBERTURA(
          VAR_TIP_SER IN INFOX_SESSION.TIP_SER%TYPE,
          VAR_COBERTURA IN INFOX_SESSION.COBERTURA%TYPE,
          VAR_TIP_REC IN INFOX_SESSION.TIP_REC%TYPE,
          VAR_RECLAMANTE IN INFOX_SESSION.AFILIADO%TYPE,
          VAR_TIP_SER2 IN OUT INFOX_SESSION.TIP_SER%TYPE,
          VAR_TIP_COB IN OUT REC_C_SAL.TIP_COB%TYPE,
          VAR_DSP4 IN OUT SER_SAL.DESCRIPCION%TYPE,
          VAR_DSP2 IN OUT TIP_C_SAL.DESCRIPCION%TYPE,
          VAR_DSP3 IN OUT COB_SAL.DESCRIPCION%TYPE,
          NO_M_LIM_AFI IN OUT NO_M_COB.LIMITE%TYPE,
          NO_M_POR_DES IN OUT NO_M_COB.POR_DES%TYPE
        )
    --VAR_FEC_VER    IN DATE DEFAULT SYSDATE,--
    --VAR_CAT_N_MED  IN INFOX_SESSION.CAT_N_MED%TYPE,--
    --VAR_DAT_ASEG IN C_DAT_ASEG%ROWTYPE )--
        RETURN NUMBER IS
          ERROR CHAR(1) := NULL;
        BEGIN
          V_SERV_EME := DBAPER.BUSCA_PARAMETRO('TIP_SERV_CONS_MEDI_3', FONOS_ROW.COMPANIA);
          DBMS_OUTPUT.PUT_LINE('Entro 2:  ');
          P_USUARIO_FONO; -- llama procedure para asignar el usuario a la variable vUsuario
          DBMS_OUTPUT.PUT_LINE('Datos_Cobertura_Asegurados:  '
            ||ERROR);
          IF FONOS_ROW.TIP_REC = 'ASEGURADO' THEN
            ERROR := PAQ_MATRIZ_VALIDACIONES.DATOS_COBERTURA_ASEGURADOS(VAR_TIP_SER, VAR_COBERTURA, VAR_TIP_SER2, VAR_TIP_COB, VAR_DSP4, VAR_DSP2, VAR_DSP3);
            DBMS_OUTPUT.PUT_LINE('Datos_Cobertura_Asegurados:  '
              ||ERROR);
          ELSIF FONOS_ROW.TIP_REC = 'NO_MEDICO' THEN
            ERROR := PAQ_MATRIZ_VALIDACIONES.DATOS_COBERTURA_NO_MEDICO(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, VAR_RECLAMANTE, VAR_TIP_SER, FONOS_ROW.PLAN, VAR_COBERTURA, VAR_TIP_SER2, VAR_TIP_COB, VAR_DSP4, VAR_DSP2, VAR_DSP3, NO_M_LIM_AFI, NO_M_POR_DES);
            DBMS_OUTPUT.PUT_LINE('Datos_Cobertura_No_Medico:  '
              ||ERROR);
          ELSIF FONOS_ROW.TIP_REC = 'MEDICO' THEN
            ERROR := PAQ_MATRIZ_VALIDACIONES.DATOS_COBERTURA_MEDICO(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, VAR_RECLAMANTE,
    --VAR_CAT_N_MED,
            VAR_TIP_SER, FONOS_ROW.PLAN, VAR_COBERTURA, VAR_TIP_SER2, VAR_TIP_COB, VAR_DSP4, VAR_DSP2, VAR_DSP3, NO_M_LIM_AFI, NO_M_POR_DES);
          END IF;
          RETURN(ERROR);
        END;
        PROCEDURE CALCULAR_RESERVA(
          LIM_AFI IN NO_M_COB.LIMITE%TYPE,
          POR_DES IN NO_M_COB.POR_DES%TYPE,
          POR_COA IN POL_P_SER.POR_COA%TYPE,
          MON_PAG IN OUT REC_C_SAL.MON_PAG%TYPE,
          MON_POR_COA IN OUT INFOX_SESSION.MON_PAG%TYPE,
          P_MON_EXE IN NUMBER,
          P_MON_ACUM IN NUMBER
        ) IS
        BEGIN
          IF P_MON_EXE IS NOT NULL AND P_MON_EXE <> 0 THEN
            IF P_MON_ACUM > P_MON_EXE THEN
              MON_POR_COA := ROUND((LIM_AFI * POR_COA / 100), 2);
            ELSIF (P_MON_ACUM + LIM_AFI) > P_MON_EXE THEN
              MON_POR_COA := ROUND(((((LIM_AFI + P_MON_ACUM) - P_MON_EXE) * POR_COA) / 100), 2);
            END IF;
            MON_PAG := (LIM_AFI - NVL(MON_POR_COA, 0));
          ELSE
            MON_POR_COA := ROUND((LIM_AFI * POR_COA / 100), 2);
            MON_PAG := (LIM_AFI - NVL(MON_POR_COA, 0));
          END IF;
        END;
    /* Rutina Principal */
      BEGIN
        P_USUARIO_FONO; -- llama procedure para asignar el usuario a la variable vUsuario
        FECHA_DIA := TO_DATE(TO_CHAR(SYSDATE, 'dd/mm/yyyy'), 'dd/mm/yyyy');
        OPEN A;
        FETCH A INTO FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE, FONOS_ROW.SEXO, FONOS_ROW.FEC_ING, FONOS_ROW.FEC_NAC, FONOS_ROW.ANO_REC, FONOS_ROW.SEC_REC, FONOS_ROW.CATEGORIA, FONOS_ROW.EST_CIV, FONOS_ROW.MON_REC_AFI, FONOS_ROW.CAT_N_MED, FONOS_ROW.TIP_SER;
    --- COMENTADO PORQUE YA NO SE ESTARA CAMBIANDO PARA LA ARS PARA LAS PRUEBAS COVID SOLICTUD SYSIAD 132688
    --- LEONARDO MANCEBO RIVAS 31 03 2022

    /*       V_PSS_NO_CAMBIA_COVID := NULL;
                OPEN C_PSS_NO_CAMBIA_COVID (FONOS_ROW.AFILIADO);
                FETCH C_PSS_NO_CAMBIA_COVID INTO V_PSS_NO_CAMBIA_COVID;
                CLOSE C_PSS_NO_CAMBIA_COVID;

          ---- VALIDACION DE CAMBIO DE COMPANIA Y PLAN PARA AFILIADOS CON BASICO VIGENTE EN PRUEBA DE COVID -- 12 04 2021 LEONARDO
          IF V_PSS_NO_CAMBIA_COVID IS NULL
            THEN*/
        IF FONOS_ROW.RAMO <> 94 THEN
    --IF TO_NUMBER(SUBSTR(P_INSTR1, 5, 10)) = 7651 --- COBERTURA COVID, --comentado por wrs, v 1.00
    --IF TO_NUMBER(SUBSTR(P_INSTR1, 5, 10)) = 7651 or TO_NUMBER(SUBSTR(P_INSTR1, 3, 2)) = 7 --agregado por wrs v 1.00
          IF TO_NUMBER(SUBSTR(P_INSTR1, 3, 2)) = 7 --descomentado por ecruzc porque estaba dejando pasar los pyp por los planes voluntarios
          THEN
            IF DBAPER.F_AFILIADO_VIGENTE_BASICO(FONOS_ROW.ASEGURADO, NVL(FONOS_ROW.DEPENDIENTE, 0), TRUNC(SYSDATE)) -- DETERMINA SI EL AFILIADO TIENE EL BASICO VIGENTE
            THEN
              FONOS_ROW.COMPANIA := 96;
              FONOS_ROW.RAMO := 94;
              FONOS_ROW.SECUENCIAL := 29981;
              FONOS_ROW.PLAN := 230;
    ---
              UPDATE INFOX_SESSION
              SET
                COMPANIA = FONOS_ROW.COMPANIA,
                RAMO = FONOS_ROW.RAMO,
                SECUENCIAL = FONOS_ROW.SECUENCIAL,
                PLAN = FONOS_ROW.PLAN
              WHERE
                NUMSESSION = P_NUMSESSION;
            END IF;
          END IF;
        END IF;
    --END IF;
    ---- FIN VALIDACION DE CAMBIO DE COMPANIA Y PLAN PARA AFILIADOS CON BASICO VIGENTE EN PRUEBA DE COVID -- 12 04 2021
        IF A%FOUND THEN
          V_INTERNACIONAL := NULL;
          IF FONOS_ROW.RAMO != 93 AND INSTR(V_PARAM, ','
            || FONOS_ROW.PLAN
            || ',') = 0 THEN
    --<84770> jdeveaux --> Si es un plan internacional se procesa por el proceso internacional
            OPEN D;
            FETCH D INTO VAR_CATEGORIA;
            CLOSE D;
    --
            COD_ASE := TO_NUMBER(FONOS_ROW.ASEGURADO);
            COD_DEP := TO_NUMBER(FONOS_ROW.DEPENDIENTE);
    --
            IF NVL(COD_DEP, 0) = 0 THEN
              VAR_TIP_A_USO := 'ASEGURADO';
            ELSE
              VAR_TIP_A_USO := 'DEPENDIENT';
            END IF;
    --
            IF FONOS_ROW.TIP_REC = 'NO_MEDICO' THEN
              OPEN B;
              FETCH B INTO DES_TIP_N_MED;
              CLOSE B;
            ELSE
              DES_TIP_N_MED := FONOS_ROW.TIP_REC;
            END IF;
    --
            OPEN C;
            FETCH C INTO VAR_FEC_INI, VAR_FEC_FIN;
            CLOSE C;
    --

    /*codigo nuevo*/
            V_INSER := TO_NUMBER(SUBSTR(P_INSTR1, 1, 2));
            V_INTIP := TO_NUMBER(SUBSTR(P_INSTR1, 3, 2));
            V_INCOB := SUBSTR(P_INSTR1, 5, 10);
            IF V_INTIP = 7 THEN
              V_INSER := 6; --wrs 1.0,22/09/2021
    --V_INSER := 8; --TP 09/11/2018 Enfoco wrs comento 1.0, 22/09/2021
    --
    --<00062> jdeveaux 27nov2017 Se valida la red dental del afiliado para determinar servicio

    /*V_RED_PLAT := DBAPER.F_VALIDA_RED_DENTAL_PLATINUM(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, V_MSG);
                IF  V_RED_PLAT = 8 THEN
                    V_INSER :=  V_RED_PLAT;
                ELSE
                    V_INSER := 1;
                END IF;*/
    --</00062>
            ELSIF V_INTIP > 7 AND V_INTIP <> 76 THEN
              V_INSER := 3;
            ELSE
              V_INSER := 1;
            END IF;
    -- Procedimiento que valida si la cobertura es un estudio a Repeticion  Miguel A.Carrion 06/09/2021
            VESTUDIO_REPETICION := BUSCA_COB_ESTUDIO_REPETICION(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE, FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.TIP_SER, NVL(FONOS_ROW.TIP_COB, V_INTIP), NVL(FONOS_ROW.COBERTURA, V_INCOB), VUSUARIO);
            DBMS_OUTPUT.PUT_LINE('vESTUDIO_REPETICION->:  '
              ||VESTUDIO_REPETICION);
            IF NVL(VESTUDIO_REPETICION, 'N') = 'S' THEN
    /*Procedimiento que busca en que bajo que servicio fue que se realizo la autorizacion de la cobertura de estudio
                              a repeticion y la parametrizacion de la cantidad y rango de fecha la cual iniciara y concluira el ciclo de la
                              autorizacion Miguel A. Carrion  06/09/2021*/
              P_ESTUDIO_REPETICION(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE, NVL(FONOS_ROW.COBERTURA, V_INCOB), FONOS_ROW.COMPANIA, P_CANTIDAD, P_FEC_VER, P_FEC_FIN, P_SERVICIO, P_TIP_COB, P_ERROR );
              IF P_ERROR = 0 THEN
    --
                V_INSER := P_SERVICIO;
                V_INTIP := P_TIP_COB;
    --

    /*Funcion que valida si el afiliado concluyo con el ciclo de autorizacion segun lo parametrizado
                              para la cobertura a repeticion Miguel A. Carrion 6/09/2021*/
                ERROR := F_VALIDAR_CICLO_COBERTURA_REP (VAR_ESTATUS_CAN, VAR_TIP_A_USO, FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE, P_SERVICIO, P_TIP_COB, NVL(FONOS_ROW.COBERTURA, V_INCOB), FECHA_DIA, P_FEC_VER, P_FEC_FIN, P_CANTIDAD, FONOS_ROW.COMPANIA );
                DBMS_OUTPUT.PUT_LINE(' FECHA_DIA:-> '
                  ||FECHA_DIA);
                DBMS_OUTPUT.PUT_LINE(' P_FEC_VER:-> '
                  ||P_FEC_VER);
                DBMS_OUTPUT.PUT_LINE(' P_FEC_FIN:-> '
                  ||P_FEC_FIN);
                IF ERROR IS NOT NULL OR FECHA_DIA NOT BETWEEN P_FEC_VER AND P_FEC_FIN THEN
    --
                  V_COD_ERROR := 2;
    --
                  DBMS_OUTPUT.PUT_LINE('F_VALIDAR_CICLO_COBERTURA_REP->:  '
                    ||V_COD_ERROR);
                END IF;
              ELSE
    --
                V_COD_ERROR := 2;
    --
              END IF;
            END IF;
    --TP 09/11/2018 Enfoco
            IF FONOS_ROW.TIP_REC = 'MEDICO' THEN
              OPEN CAT_MEDICO(FONOS_ROW.AFILIADO);
              FETCH CAT_MEDICO INTO V_CAT;
              IF CAT_MEDICO%FOUND THEN
                V_INSER := 8;
              END IF;
              CLOSE CAT_MEDICO;
            ELSE
              OPEN CAT_N_MED(FONOS_ROW.AFILIADO);
              FETCH CAT_N_MED INTO V_CAT;
              IF CAT_N_MED%FOUND THEN
                V_INSER := 8;
              END IF;
              CLOSE CAT_N_MED;
            END IF;
    --TP 09/11/2018 Enfoco
    --Miguel A. Carrion se agrego cursor para validar si el afiliado posee un proveedor de odontologia 21/07/2020
            IF V_INSER = 8 THEN
    --
              OPEN C_PROVEEDOR(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, V_INSER);
              FETCH C_PROVEEDOR INTO V_PROVEEDOR;
              IF C_PROVEEDOR%NOTFOUND AND (NOT VALIDA_RECLAMANTE(FONOS_ROW.AFILIADO)) THEN
    --
    --
                V_COD_ERROR := 2;
    --
    --
              END IF;
    --
              CLOSE C_PROVEEDOR;
    --
            END IF;
    ---Miguel A. Carrion 14/01/2021 Se agrego condicion ya que los procesos busca la fecha de version real del afiliado cuando es basico o voluntario.
            IF FONOS_ROW.PLAN = DBAPER.BUSCA_PARAMETRO('PLAN_PBS', FONOS_ROW.COMPANIA) OR V_INSER = DBAPER.BUSCA_PARAMETRO('TIP_SERV_CONS_MEDI_0', FONOS_ROW.COMPANIA) THEN
              VAR_FEC_INI := F_FECHA_EFECTIVIDAD(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE); --Funcion para buscar la fecha de efectividad del afiliado Miguel A. Carrion 13/09/2022
              IF VAR_FEC_INI IS NULL THEN
    ---
                VAR_FEC_INI := FDP_FECVER_AC(FONOS_ROW.COMPANIA, --:PRE_CERTIF.COM_POL,
                FONOS_ROW.RAMO, --:PRE_CERTIF.RAM_POL,
                FONOS_ROW.SECUENCIAL, --:PRE_CERTIF.SEC_POL,
                SYSDATE, FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE);
    --
              END IF;
            ELSIF V_INSER = DBAPER.BUSCA_PARAMETRO('GMM', FONOS_ROW.COMPANIA) THEN
    /*Funcion para buscar la fecha de version para los afiliado bajo el servicio de Gmm Miguel A. Carrion 14/01/2021 */
              VAR_FEC_INI := FDP_FECVER (FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, SYSDATE, FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE, '');
            END IF;
    --SI AUN NO SE HA GENERADO UNA RECLAMACION TOMA EL SERVICIO DEL VALOR DIGITADO--
    --EN CASO CONTRARIO TOMA EL SERVICIO DE LA RECLAMACION YA INSERTADA--
            IF (NVL(FONOS_ROW.SEC_REC, 0) = 0) THEN
              FONOS_ROW.TIP_SER := V_INSER;
            END IF;
    --
            FONOS_ROW.TIP_COB := V_INTIP;
            FONOS_ROW.COBERTURA := V_INCOB;
            VAR_TIP_SER2 := FONOS_ROW.TIP_SER;
    --Enfoco mcarrion 12/02/2019
            IF (FONOS_ROW.TIP_REC = 'NO_MEDICO'
            AND FONOS_ROW.TIP_SER = 8) OR (FONOS_ROW.TIP_REC = 'MEDICO'
            AND FONOS_ROW.TIP_SER = 8) THEN
              OPEN CUR_PROV_CAPITADO;
              FETCH CUR_PROV_CAPITADO INTO V_PROV_CAPITADO, V_PROV_BASICO;
              CLOSE CUR_PROV_CAPITADO;
              OPEN CAP_BASICO(FONOS_ROW.AFILIADO);
              FETCH CAP_BASICO INTO V_PROV_EXISTE;
              CLOSE CAP_BASICO;
              OPEN NUEVO(V_PROV_BASICO);
              FETCH NUEVO INTO V_NUEVO;
              CLOSE NUEVO;
              IF V_PROV_CAPITADO = 1 AND NVL(V_PROV_EXISTE, 0) = 0 AND NVL(V_NUEVO, 'N') = 'N' THEN
    --
                V_COD_ERROR := 2;
    --
              ELSE
                IF ((FONOS_ROW.TIP_REC = 'NO_MEDICO'
                AND FONOS_ROW.TIP_SER = 8)
                OR (FONOS_ROW.TIP_REC = 'MEDICO'
                AND FONOS_ROW.TIP_SER = 8)) THEN
                  OPEN CUR_CAT_PROV;
                  FETCH CUR_CAT_PROV INTO V_PROVEEDOR, V_CATEGORIA;
                  CLOSE CUR_CAT_PROV;
                END IF;
              END IF;
            END IF;
    ---Enfoco mcarrion 12/02/2019
    --

    /*PROCEDIMIENTO PARA PROBAR
              FONOS_ROW.COBERTURA := P_INSTR1;
                FONOS_ROW.TIP_COB   := 5;
                FONOS_ROW.TIP_SER   := 1;*/
            IF NVL(COD_ASE, 0) = 0 THEN
              VAR_CODE := 1;
            END IF;
    --  IF VAR_CODE IS NULL OR VAR_CODE <> 2 THEN
            IF NVL(COD_ASE, 0) <> 0 THEN
              OPEN C_COBERTURA;
              FETCH C_COBERTURA INTO DUMMY;
              IF C_COBERTURA%NOTFOUND THEN
                ERROR := '1';
              END IF;
              CLOSE C_COBERTURA;
              IF ERROR IS NULL THEN
    /*OPEN C_DAT_ASEG;
                  FETCH C_DAT_ASEG INTO DAT_ASEG_ROW;
                  CLOSE C_DAT_ASEG;*/
                ERROR := BUSCAR_DATOS_COBERTURA(FONOS_ROW.TIP_SER, FONOS_ROW.COBERTURA, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, VAR_TIP_SER2, FONOS_ROW.TIP_COB, SER_SAL_ROW.DESCRIPCION, TIP_C_SAL_ROW.DESCRIPCION, COB_SAL_ROW.DESCRIPCION, NO_M_COB_ROW.LIMITE, NO_M_COB_ROW.POR_DES);
                DBMS_OUTPUT.PUT_LINE('BUSCAR_DATOS_COBERTURA:  '
                  ||ERROR);
    --<jdeveaux 18may2016>

    /*Procedimiento para validar si el prestador de servicios se encuentra en la red del plan basico si no esta en la red de la poliza voluntario.*/
    /*Si se da esta condicion, todas las validaciones posteriores de coberturas deben hacerse bajo la configuracion del plan basico (ramo, secuencial, plan)*/
                DECLARE
                  RED_VOLUNTARIO     BOOLEAN;
                  RED_EXCEPCION_ODON BOOLEAN;
                  RED_PBS            BOOLEAN;
                  V_PLAN_PBS         NUMBER(3);
                  V_COMPANIA_PBS     NUMBER(2);
                  V_RAMO_PBS         NUMBER(2);
                  V_SEC_PBS          NUMBER(7);
                BEGIN
    --Se limpian las variables
                  V_PLAN_PBS := NULL;
                  V_COMPANIA_PBS := NULL;
                  V_RAMO_PBS := NULL;
                  V_SEC_PBS := NULL;
    --
    --Solo debe funcionar para las polizas voluntarias
                  IF FONOS_ROW.RAMO = 95 THEN
    --Valida si el proveedor pertenece a la red del plan voluntario
                    RED_VOLUNTARIO := PAQ_MATRIZ_VALIDACIONES.VALIDAR_PLAN_AFILIADO(FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO);
    ---MCARRION 26/06/2019
                    RED_EXCEPCION_ODON := DBAPER.EXCEPCION_POLIZA_ODON(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.TIP_SER);
                    V_SIMULTANEO := DBAPER.PAQ_MATRIZ_VALIDACIONES.VALIDA_SIMULTANEIDAD(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE, FONOS_ROW.COMPANIA);
                    DBMS_OUTPUT.PUT_LINE('V_SIMULTANEO->:  '
                      ||V_SIMULTANEO);
                    IF (NOT (RED_VOLUNTARIO)
                    AND NOT (RED_EXCEPCION_ODON)
                    AND /*(V_INSER = 13)*/ V_SIMULTANEO = 'S') OR (V_INSER = DBAPER.BUSCA_PARAMETRO('TIP_SERV_CONS_MEDI_0', FONOS_ROW.COMPANIA)
                    AND V_SIMULTANEO = 'S') THEN
    --Busca los datos de la poliza del plan basico
                      IF (VALIDA_RECLAMANTE(FONOS_ROW.AFILIADO)) THEN
                        V_PROVEEDOR := NULL;
                      END IF;
    --v_categoria  := null;
                      DBAPER.POLIZA_PLAN_BASICO(V_COMPANIA_PBS, V_RAMO_PBS, V_SEC_PBS, V_PLAN_PBS);
    --JD FOREBRA <TRANSPLANTE RENAL>
                      IF F_PACIENTE_RENAL(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE) = 'S' AND F_COBERTURA_RENAL(FONOS_ROW.COBERTURA) = 'S' THEN
                        V_INSER := TO_NUMBER(PKG_GENERAL.F_OBTEN_PARAMETRO_SEUS('SERVICIO_RENAL', 96));
                        V_INTIP := F_TIP_COB_RENAL(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE);
                        FONOS_ROW.TIP_SER := V_INSER;
                        FONOS_ROW.TIP_COB := V_INTIP;
                      END IF;
    /* Si el servicio es Alto Costo entonces busca la fecha de version del afiliado
                          y la gradualidad segun las cotizaciones o aporte que tenga el afiliado
                            Miguel A. Carrion 14/01/2021  */
                      IF V_INSER = DBAPER.BUSCA_PARAMETRO('TIP_SERV_CONS_MEDI_0', FONOS_ROW.COMPANIA) OR V_INSER = TO_NUMBER(PKG_GENERAL.F_OBTEN_PARAMETRO_SEUS('SERVICIO_RENAL', 96)) THEN
                        F_FEC_VER := F_FECHA_EFECTIVIDAD(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE); --Funcion para buscar la fecha de efectividad del afiliado Miguel A. Carrion 13/09/2022
                        IF F_FEC_VER IS NULL THEN
    --
                          F_FEC_VER := DBAPER.FDP_FECVER_AC(V_COMPANIA_PBS, -- :RECLAMAC12.COMPANIA,
                          V_RAMO_PBS, -- :RECLAMAC12.RAMO,
                          V_SEC_PBS, --:RECLAMAC12.SEC_POL,
                          FECHA_DIA, FONOS_ROW.ASEGURADO, NVL(FONOS_ROW.DEPENDIENTE, 0));
                        END IF;
    --
                        V_FEC_FINAL := ADD_MONTHS(F_FEC_VER, 12);
    --
    -- proceso para buscar lo consumido y disponible del afiliado
    -- enviado como parametro para el servicio alto costo.
                        DBAPER.PKG_ADMIN_ALTO_COSTO.BUSCA_DISPONIBLE(V_COMPANIA_PBS, V_PLASTICOS, -- :p_num_pla     ,
                        NULL, -- :p_nss         ,
                        FONOS_ROW.ASEGURADO, -- :p_asegurado   ,
                        NVL(FONOS_ROW.DEPENDIENTE, 0), -- :p_dependiente ,
                        V_FEC_FINAL, --:reclamac12.fec_ser                 ,  -- :p_fec_ser     ,
                        V_LIM_AC, -- :p_mon_max     ,
                        V_TOTAL_CONSUMO, -- :p_consumido   ,
                        V_BCE_AC, -- :p_disponible);
                        F_FEC_VER, V_INTIP);
                        VALOR_MAX_AC := F_OBTIENE_MON_MAX_GRADUAL(V_NSS, FECHA_DIA, V_COMPANIA_PBS, V_INSER);
                        VALOR_MAX_AC := ROUND(NVL(VALOR_MAX_AC, 0) - NVL(V_TOTAL_CONSUMO, 0));
                        IF VALOR_MAX_AC <= 0 THEN
    --
                          V_COD_ERROR := 4;
    --
                        END IF;
                      END IF;
    ---Miguel A. Carrion 24/08/2020
    --Valida si el proveedor pertenece a la red del plan basico
                      RED_PBS := PAQ_MATRIZ_VALIDACIONES.VALIDAR_PLAN_AFILIADO(V_PLAN_PBS, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO);
                      IF RED_PBS THEN
    --Guarda en variables los datos originales de la poliza voluntaria
                        V_PLAN_ORI := FONOS_ROW.PLAN;
                        V_COMPANIA_ORI := FONOS_ROW.COMPANIA;
                        V_RAMO_ORI := FONOS_ROW.RAMO;
                        V_SEC_ORI := FONOS_ROW.SECUENCIAL;
    --Cambia los datos de poliza y plan a los del Plan Basico. Esto debe ser restaurado antes de salir de VALIDATECOBERTURA
                        FONOS_ROW.PLAN := V_PLAN_PBS;
                        FONOS_ROW.COMPANIA := V_COMPANIA_PBS;
                        FONOS_ROW.RAMO := V_RAMO_PBS;
                        FONOS_ROW.SECUENCIAL := V_SEC_PBS;
                      END IF;
                    END IF;
                  END IF;
                END;
    --</jdeveaux>
    --JD FOREBRA <TRANSPLANTE RENAL>
                IF F_PACIENTE_RENAL(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE) = 'S' AND F_COBERTURA_RENAL(FONOS_ROW.COBERTURA) = 'S' THEN
                  V_INSER := TO_NUMBER(PKG_GENERAL.F_OBTEN_PARAMETRO_SEUS('SERVICIO_RENAL', 96));
                  V_INTIP := F_TIP_COB_RENAL(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE);
                  FONOS_ROW.TIP_SER := V_INSER;
                  FONOS_ROW.TIP_COB := V_INTIP;
                END IF;
    /* Si el servicio es alto costo y el ramo es el ramo del basico, busca la fecha de version del afiliado
                          y la gradualidad segun los aporte o cotizaciones  Miguel A. Carrion 14/01/2021   */
                IF (V_INSER = DBAPER.BUSCA_PARAMETRO('TIP_SERV_CONS_MEDI_0', FONOS_ROW.COMPANIA)
                OR V_INSER = TO_NUMBER(PKG_GENERAL.F_OBTEN_PARAMETRO_SEUS('SERVICIO_RENAL', 96))) AND FONOS_ROW.RAMO = DBAPER.BUSCA_PARAMETRO('BASICO', FONOS_ROW.COMPANIA) THEN
                  F_FEC_VER := F_FECHA_EFECTIVIDAD(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE); --Funcion para buscar la fecha de efectividad del afiliado Miguel A. Carrion 13/09/2022
                  IF F_FEC_VER IS NULL THEN
                    F_FEC_VER := DBAPER.FDP_FECVER_AC(FONOS_ROW.COMPANIA, -- :RECLAMAC12.COMPANIA,
                    FONOS_ROW.RAMO, -- :RECLAMAC12.RAMO,
                    FONOS_ROW.SECUENCIAL, --:RECLAMAC12.SEC_POL,
                    FECHA_DIA, FONOS_ROW.ASEGURADO, NVL(FONOS_ROW.DEPENDIENTE, 0));
                  END IF;
    --
                  V_FEC_FINAL := ADD_MONTHS(F_FEC_VER, 12);
    --
    -- proceso para buscar lo consumido y disponible del afiliado
    -- enviado como parametro para el servicio alto costo.
                  DBAPER.PKG_ADMIN_ALTO_COSTO.BUSCA_DISPONIBLE(FONOS_ROW.COMPANIA, V_PLASTICOS, -- :p_num_pla     ,
                  NULL, -- :p_nss         ,
                  FONOS_ROW.ASEGURADO, -- :p_asegurado   ,
                  NVL(FONOS_ROW.DEPENDIENTE, 0), -- :p_dependiente ,
                  V_FEC_FINAL, --:reclamac12.fec_ser                 ,  -- :p_fec_ser     ,
                  V_LIM_AC, -- :p_mon_max     ,
                  V_TOTAL_CONSUMO, -- :p_consumido   ,
                  V_BCE_AC, -- :p_disponible);
                  F_FEC_VER, V_INTIP);
                  VALOR_MAX_AC := F_OBTIENE_MON_MAX_GRADUAL(V_NSS, FECHA_DIA, FONOS_ROW.COMPANIA, V_INSER);
                  VALOR_MAX_AC := ROUND(NVL(VALOR_MAX_AC, 0) - NVL(V_TOTAL_CONSUMO, 0));
                  IF VALOR_MAX_AC <= 0 THEN
    --
                    V_COD_ERROR := 4;
    --
                  END IF;
                END IF;
    ---Miguel A. Carrion 24/08/2020

    /* Si el servicio es Gmm, busca la fecha de version del afiliado y el limite y consumo
                          Miguel A. Carrion 14/01/2021  */
                IF V_INSER = DBAPER.BUSCA_PARAMETRO('GMM', FONOS_ROW.COMPANIA) THEN
                  F_FEC_VER := DBAPER.FDP_FECVER (FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FECHA_DIA, FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE, '');
    --
                  V_FEC_FINAL_GMM := ADD_MONTHS(F_FEC_VER, 12);
    --
                  VAR_TIP_REC := SUBSTR(DES_TIP_N_MED, 1, 10);
                  P_LIM_GMM(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, VAR_TIP_REC, VAR_TIP_A_USO, VALOR_MAX_GMM, FECHA_DIA, 'N', FONOS_ROW.ASEGURADO, NVL(FONOS_ROW.DEPENDIENTE, 0), NULL, V_NOTAS, FONOS_ROW.FEC_NAC);
                  BALANCE_GMM := FDP_BALANCE(FONOS_ROW.ASEGURADO, NVL(FONOS_ROW.DEPENDIENTE, 0), FONOS_ROW.TIP_SER, F_FEC_VER, V_FEC_FINAL_GMM, FECHA_DIA, FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL);
                  VALOR_MAX_GMM := ROUND(NVL(VALOR_MAX_GMM, 0) - NVL(BALANCE_GMM, 0), 2);
                  IF VALOR_MAX_GMM <= 0 THEN
                    V_COD_ERROR := 4;
                  END IF;
                END IF;
    ---Miguel A. Carrion 24/08/2020
    --END IF;

    /* Funcion que valida si el afiliado tiene una pre_certificacion vigente Miguel A. Carrion 19/07/2021*/
                V_SECUENCIAL_PRECERT := NVL(DBAPER.F_VALIDA_PRECERTIF_FECH_DUPL(FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, VAR_TIP_A_USO, COD_ASE, COD_DEP, V_INSER, FONOS_ROW.COBERTURA), 0);
                DBMS_OUTPUT.PUT_LINE('V_Secuencial_precert->:  '
                  ||V_SECUENCIAL_PRECERT);
                IF V_SECUENCIAL_PRECERT != 0 THEN
    --
                  V_COD_ERROR := 2;
                  P_OUTNUM2 := V_SECUENCIAL_PRECERT;
    --
                END IF;
    -- Fin Miguel A. Carrion 06/05/2021
                IF F_COBERTURA_HOMOLOGADA(FONOS_ROW.COBERTURA) IS NULL THEN
                  IF ERROR IS NULL THEN
    -- Enfoco - 05/11/2018
                    PAQ_MATRIZ_VALIDACIONES.BUSCA_RANGOS_COBERTURA(FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, P_RAN_U_EXC, P_RAN_U_MAX);
    /* ---------------------------------------------------------------------- */
    /*   Determina Origen de la Cobertura                                     */
    /* ---------------------------------------------------------------------- */
    --
                    OPEN C_PLAN_EXCEPTION;
                    FETCH C_PLAN_EXCEPTION INTO M_PLAN_EXCEPTION;
                    CLOSE C_PLAN_EXCEPTION;
                    OPEN C_VALIDA_PLAN_EXCENTO(FONOS_ROW.PLAN, M_PLAN_EXCEPTION);
                    FETCH C_VALIDA_PLAN_EXCENTO INTO M_VALIDA_PLAN;
    --FONOS_ROW.PLAN
                    IF C_VALIDA_PLAN_EXCENTO%NOTFOUND THEN
                      IF PAQ_MATRIZ_VALIDACIONES.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, VUSUARIO) = FALSE THEN
                        ORI_FLAG := PAQ_MATRIZ_VALIDACIONES.BUSCA_ORIGEN_COB(FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, VUSUARIO, FONOS_ROW.RAMO, FONOS_ROW.COMPANIA);
                        IF ORI_FLAG IS NOT NULL THEN
                          ERROR := '1';
                        END IF;
    /**IF ERROR IS NOT NULL THEN
                          vESTUDIO_REPETICION := BUSCA_COB_ESTUDIO_REPETICION(FONOS_ROW.ASEGURADO,
                                                                              FONOS_ROW.DEPENDIENTE,
                                                                              FONOS_ROW.COMPANIA,
                                                                              FONOS_ROW.RAMO,
                                                                              FONOS_ROW.SECUENCIAL,
                                                                              FONOS_ROW.TIP_SER,
                                                                              FONOS_ROW.TIP_COB,
                                                                              FONOS_ROW.COBERTURA,
                                                                              vUsuario);

                          IF NVL(vESTUDIO_REPETICION, 'N') = 'S' THEN
                            ERROR := NULL;
                          END IF;
                        END IF;**/
                        IF ERROR IS NULL THEN
    -- Htorres - 29/09/2019
    -- Monto maximo que se pueda otorgar para esa cobertura por canales
                          VMON_MAX_COB_ORIGEN := BUSCA_ORIGEN_COB_MON_MAX(FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, VUSUARIO);
                        END IF;
                      END IF;
                    END IF;
                    CLOSE C_VALIDA_PLAN_EXCENTO;
                    IF ERROR IS NULL THEN
    /* ----------------------------------------------------------------------*/
    /* --------------------------------------------------------------------- */
    /*  Busca Limite de monto por cobertura de salud                         */
    /* --------------------------------------------------------------------- */
    /* If..End if adicionado para condicionar si la poliza esta exento
                        de restriccion.  Roche Louis/TECHNOCONS. d/f 17-Dic-2009 8:57am
                      */
                      IF PAQ_MATRIZ_VALIDACIONES.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, VUSUARIO) = FALSE THEN
    --
                        LIMITE_LABORATORIO := PAQ_MATRIZ_VALIDACIONES.TIP_COB_MON_MAX(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, P_MON_EXE, P_UNI_T_EXE, P_RAN_EXE, P_POR_COA, P_UNI_T_MAX);
    --
                      END IF;
    --
    --P_MON_DED_TIP_COB);

    /* --------------------------------------------------------------------- */
    /* Valida que el Asegurado puede Recibir la Cobertura de Salud.          */
    /* --------------------------------------------------------------------- */
                      ERROR := PAQ_MATRIZ_VALIDACIONES.CHK_COBERTURA_ASEGURADO_FONO(TRUE, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, DES_TIP_N_MED, VAR_TIP_A_USO, COD_ASE, COD_DEP, FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, VAR_TIP_SER2, FECHA_DIA, FONOS_ROW.SEXO, FONOS_ROW.EST_CIV, VAR_CATEGORIA, FONOS_ROW.FEC_NAC, POR_COA, NO_M_COB_ROW.LIMITE, PLA_STC_ROW.FRECUENCIA, PLA_STC_ROW.UNI_TIE_F, PLA_STC_ROW.TIE_ESP, PLA_STC_ROW.UNI_TIE_T, PLA_STC_ROW.MON_MAX, --A--
                      PLA_STC_ROW.UNI_TIE_M, PLA_STC_ROW.SEXO, PLA_STC_ROW.EDA_MIN, PLA_STC_ROW.EDA_MAX, P_DSP_EST_CIV, P_DSP_CATEGORIA, MONTO_CONTRATADO, VUSUARIO, P_POR_COA, P_MONTO_MAX, --A estaba dos veces--
                      PLA_STC_ROW.EXC_MCA, PLA_STC_ROW.MON_DED, V_CATEGORIA, V_PROVEEDOR);
                      DBMS_OUTPUT.PUT_LINE('CHK_COBERTURA_ASEGURADO_FONO:  '
                        ||ERROR);
    /*Condicion para poder validar la cantidad de frecuencia recibida VS la frencuencia para metrizada,
                      Si la frencuencia recibida es mayor a la frecuencia parametrizada para la cobertura presentara*
                      Error 2  Miguel A. Carrion 19/08/2022 Autorizador Odontologico*/
                      IF P_INNUM1 IS NOT NULL AND FONOS_ROW.TIP_SER = DBAPER.BUSCA_PARAMETRO('ODONTOLOGIA', FONOS_ROW.COMPANIA) THEN
                        IF NVL(P_INNUM1, 0) > PLA_STC_ROW.FRECUENCIA THEN
    --
                          V_COD_ERROR := 2;
    --
                        END IF;
                      END IF;
                      IF ERROR IS NULL THEN
    /*---------------------------------------------------------- */
    /* Valida que no se este digitando una Reclamacion           */
    /* que ya fue reclamada por el mismo.                        */
    /* --------------------------------------------------------- */
                        SEC_RECLAMACION := PAQ_MATRIZ_VALIDACIONES.VALIDA_REC_FECHA_NULL(TRUE, VAR_ESTATUS_CAN, NVL(FONOS_ROW.ANO_REC, TO_CHAR(FECHA_DIA, 'YYYY')), --Se le agreo el nvl Para en caso que el ano llegue null Tome el ano de la fecha del dia Miguel A. Carrion 18/08/2021 FCCM
                        FONOS_ROW.COMPANIA, NVL(V_RAMO_ORI, FONOS_ROW.RAMO), -- FONOS_ROW.RAMO,      -- V_RAMO_ORI Reclamaciones Duplicadas (Victor Acevedo)  /*Se le agreo NVL para que tome el ramo de la sesion, ya que la variable viene Nula Miguel A. Carrion 18/08/2021 FCCM*/
                        FONOS_ROW.SEC_REC, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, VAR_TIP_A_USO, COD_ASE, COD_DEP, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FECHA_DIA);
                        IF SEC_RECLAMACION IS NOT NULL THEN
                          ERROR := '1';
                        END IF;
                        IF ERROR IS NULL THEN
    /* ---------------------------------------------------------- */
    /* Valida que no se este digitando una Reclamacion            */
    /* que ya fue reclamada por otro que participo en la          */
    /* aplicacion de la Cobertura.                                */
    /* ---------------------------------------------------------- */
                          ERROR := PAQ_MATRIZ_VALIDACIONES.VALIDA_REC_C_SAL_FEC(TRUE, VAR_ESTATUS_CAN, FONOS_ROW.ANO_REC, FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SEC_REC, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, VAR_TIP_A_USO, COD_ASE, COD_DEP, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FECHA_DIA);
                          IF ERROR IS NULL THEN
    /* ---------------------------------------------------------- */
    /* Valida:                                                    */
    /* 1-) Tiempo de Espera de la Cobertura                       */
    /* ---------------------------------------------------------- */
                            ERROR := PAQ_MATRIZ_VALIDACIONES.VALIDAR_TIEMPO_ESPERA(TRUE, FECHA_DIA,
    --VAR_FEC_INI,
                            FONOS_ROW.FEC_ING, PLA_STC_ROW.TIE_ESP, PLA_STC_ROW.UNI_TIE_T);
                            IF ERROR IS NULL OR ERROR = '0' -- Caso # 14282
                            THEN
    /* ---------------------------------------------------------- */
    /* Valida:                                                    */
    /* 1-) Cobertura No Exceda la Frecuencia de Uso para su       */
    /*     Tipo de Cobertura.                                     */
    /* ---------------------------------------------------------- */
    /* ***** SOLO Aplica para Tipo_Coberturas:LABORATORIOS ****** */
    /* ***** en Servicios:AMBULATORIO                      ****** */
    /* ---------------------------------------------------------- */
                              IF PAQ_MATRIZ_VALIDACIONES.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, VUSUARIO) = FALSE THEN
    --
                                ERROR := PAQ_MATRIZ_VALIDACIONES.VALIDAR_FREC_TIP_COB(TRUE, VAR_ESTATUS_CAN, VAR_TIP_A_USO, COD_ASE, COD_DEP, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FECHA_DIA, VAR_FEC_INI, FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, DSP_COB_LAB, DSP_FREC_TIP_COB);
    --
                              END IF;
    --
                              IF ERROR IS NULL THEN
    /* ---------------------------------------------------------- */
    /* Valida que en las Reclamaciones:                           */
    /* 1-) Cobertura No Exceda la Frecuencia de Uso               */
    /* 2-) Cobertura No Exceda los Montos Maximo.                 */
    /* ---------------------------------------------------------- */
                                IF PAQ_MATRIZ_VALIDACIONES.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, VUSUARIO) = FALSE THEN
                                  DBMS_OUTPUT.PUT_LINE('PLA_STC_ROW.FRECUENCIA:  '
                                    ||PLA_STC_ROW.FRECUENCIA);
                                  DBMS_OUTPUT.PUT_LINE('PLA_STC_ROW.UNI_TIE_T: '
                                    ||PLA_STC_ROW.UNI_TIE_T);
    --
                                  ERROR := PAQ_MATRIZ_VALIDACIONES.VALIDAR_FREC_COBERTURA(TRUE, VAR_ESTATUS_CAN, VAR_TIP_A_USO, COD_ASE, COD_DEP, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FECHA_DIA, VAR_FEC_INI, FONOS_ROW.FEC_ING, PLA_STC_ROW.FRECUENCIA, PLA_STC_ROW.UNI_TIE_F, PLA_STC_ROW.TIE_ESP, PLA_STC_ROW.UNI_TIE_T, PLA_STC_ROW.MON_MAX, PLA_STC_ROW.UNI_TIE_M, FONOS_ROW.COMPANIA, DSP_FREC_ACUM, DSP_MON_PAG_ACUM, FONOS_ROW.PLAN);
                                  DBMS_OUTPUT.PUT_LINE('Validar_Frec_Cobertura:  '
                                    ||ERROR);
    --
                                END IF;
    --
                                IF ERROR IS NULL THEN
    /* ---------------------------------------------------  */
    /* Determina el limite de frecuencia paralelo           */
    /* por plan por tipo de cobertura                       */
    /* ---------------------------------------------------  */
                                  IF PAQ_MATRIZ_VALIDACIONES.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, VUSUARIO) = FALSE THEN
                                    DBMS_OUTPUT.PUT_LINE('var_frecuencia->:  '
                                      ||VAR_FRECUENCIA);
                                    DBMS_OUTPUT.PUT_LINE('VAR_FEC_INI->:  '
                                      ||VAR_FEC_INI);
                                    DBMS_OUTPUT.PUT_LINE('FONOS_ROW.PLAN->:  '
                                      ||FONOS_ROW.PLAN);
    --
                                    ERROR := PAQ_MATRIZ_VALIDACIONES.VALIDAR_FREC_TIP_COB_FONO(
                                      P_FIELD_LEVEL => TRUE,
                                      P_VAR_ESTATUS_CAN => VAR_ESTATUS_CAN, -- Cancelada en la Rec
                                      P_TIP_A_USO => VAR_TIP_A_USO,
                                      P_ASE_USO => COD_ASE,
                                      P_DEP_USO => COD_DEP,
                                      P_PLAN => FONOS_ROW.PLAN,
                                      P_SERVICIO => FONOS_ROW.TIP_SER,
                                      P_TIP_COB => FONOS_ROW.TIP_COB,
                                      P_COBERTURA => FONOS_ROW.COBERTURA,
                                      P_FEC_SER => FECHA_DIA,
                                      P_FEC_INI_POL => VAR_FEC_INI,
                                      P_FEC_ING => FONOS_ROW.FEC_ING,
                                      P_FRECUENCIA => VAR_FRECUENCIA,
                                      P_UNI_TIE_F => VAR_UNI_TIE_F,
                                      P_TIE_ESP => PLA_STC_ROW.TIE_ESP,
                                      P_UNI_TIE_T => PLA_STC_ROW.UNI_TIE_T,
                                      P_MON_MAX => PLA_STC_ROW.MON_MAX,
                                      P_UNI_TIE_M => PLA_STC_ROW.UNI_TIE_M,
                                      P_DSP_FREC_ACUM => VAR_DSP_FREC_ACUM
                                    );
                                    DBMS_OUTPUT.PUT_LINE('validar_frec_tip_cob_fono:  '
                                      ||ERROR);
                                    DBMS_OUTPUT.PUT_LINE('var_dsp_frec_acum->:  '
                                      ||VAR_DSP_FREC_ACUM);
    --
                                  END IF;
    --
                                  IF ERROR IS NULL THEN
    /* ---------------------------------------------------  */
    /* Determina si el afiliado digita el Monto a Reclamar  */
    /* para igualar el limite al monto digitado             */
    /* ---------------------------------------------------  */
    --VIA FONOSALUD EL AFILIADO NO DIGITA NINGUN MONTO A RECLAMAR--
    --VIA POS EL AFILIADO DIGITA EL MONTO A RECLAMAR--
    --
                                    FONOS_ROW.MON_REC_AFI := NULL; --Se limpia la variable ya que se quedaba sucia Miguel A.Carrion 26/10/2021
    --
                                    IF NVL(TO_NUMBER(P_INSTR2), 0) > 0 THEN
                                      IF FONOS_ROW.TIP_SER = V_SERV_EME THEN -- Se coloco esta condicion para los servicios de Emergencia Miguel A. Carrion 21/10/2021
    --
                                        FONOS_ROW.MON_REC_AFI := NVL(TO_NUMBER(P_INSTR2), 0);
    --
                                      ELSE
                                        IF NVL(TO_NUMBER(P_INSTR2), 0) < NO_M_COB_ROW.LIMITE THEN
                                          FONOS_ROW.MON_REC_AFI := TO_NUMBER(P_INSTR2);
                                        ELSE
                                          FONOS_ROW.MON_REC_AFI := NO_M_COB_ROW.LIMITE;
                                        END IF;
    --
                                      END IF;
                                    END IF;
                                    IF FONOS_ROW.MON_REC_AFI IS NOT NULL AND FONOS_ROW.MON_REC_AFI <> 0 THEN
                                      NO_M_COB_ROW.LIMITE := FONOS_ROW.MON_REC_AFI;
                                    END IF;
    /*-------------------------------------------------------------- */
    /* Buscar monto acumulados de reclamaciones en periodo de tiempo,*/
    /* si tiene monto excento por tipo de cobertura                  */
    /*-------------------------------------------------------------- */
                                    P_MON_ACUM := 0;
                                    IF P_MON_EXE IS NOT NULL AND P_MON_EXE <> 0 THEN
    /* -----------------------------------------------------------------------  */
    /* Obtiene la Fecha Inicial segun la Unidad de Tiempo                       */
    /* de monto excento para determinar si ha excedido el Uso de la Cobertura.  */
    /* -----------------------------------------------------------------------  */
                                      T_FEC_INI := PAQ_MATRIZ_VALIDACIONES.DETERMINA_FECHA_RANGO(FECHA_DIA, VAR_FEC_INI, NULL, NULL, NULL, P_RAN_U_EXC, P_MON_EXE, NVL(P_UNI_T_EXE, 365));
    /* ----------------------------------------------------------------------  */
    /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto excento   */
    /* para determinar si ha excedido el Uso excento de la Cobertura.          */
    /* ----------------------------------------------------------------------  */
                                      T_FEC_FIN := PAQ_MATRIZ_VALIDACIONES.DETERMINA_FECHA_RANGO_FIN(FECHA_DIA, VAR_FEC_INI, NULL, NULL, NULL, P_MON_EXE, NVL(P_UNI_T_EXE, 365), P_RAN_U_EXC);
    /* Si la Fecha Fin es null, entonces sera igual */
    /* a la Fecha de Servicio.      */
                                      IF T_FEC_FIN IS NULL THEN
                                        T_FEC_FIN := FECHA_DIA;
                                      END IF;
                                      P_MON_ACUM := PAQ_MATRIZ_VALIDACIONES.BUSCAR_REC_ACUMULADAS(VAR_TIP_A_USO, COD_ASE, COD_DEP, FECHA_DIA, FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, VAR_ESTATUS_CAN, T_FEC_INI, T_FEC_FIN);
                                    END IF;
    /* ------------------------------------------------------------- */
    /* Procedure que llama los program unit que realizan el          */
    /* Calculo de la Reserva.                                        */
    /* ------------------------------------------------------------- */
                                    CALCULAR_RESERVA(NO_M_COB_ROW.LIMITE, NO_M_COB_ROW.POR_DES, POR_COA, FONOS_ROW.MON_PAG, FONOS_ROW.MON_DED, P_MON_EXE, P_MON_ACUM);
                                    IF FONOS_ROW.TIP_SER = V_SERV_EME THEN
    -- Funcio para buscar el monto maximo parametrizado para una cobertura X Miguel A. Carrion FCCM 15/10/2021
                                      BEGIN
                                        V_MONTO_COBER := NULL;
    --
                                        V_MONTO_COBER := F_VALIDA_MONTO_COBERTURA_WEB(FONOS_ROW.COBERTURA, FONOS_ROW.COMPANIA);
                                      EXCEPTION
                                        WHEN OTHERS THEN
                                          V_ERROR := SQLCODE;
                                          V_DESC_ERROR := SUBSTR(SQLERRM, 1, 1000);
                                          INSERT INTO DBAPER.LOG_ERRORES (
                                            PROGRAMA,
                                            USUARIO,
                                            FEC_TRA,
                                            COD_ERROR,
                                            DESC_ERROR,
                                            DATOS_ERROR
                                          ) VALUES (
                                            'F_VALIDA_MONTO_COBERTURA_WEB',
                                            USER,
                                            SYSDATE,
                                            V_ERROR,
                                            V_DESC_ERROR,
                                            FONOS_ROW.COBERTURA
                                              ||'-'
                                              ||FONOS_ROW.COMPANIA
                                          );
                                      END;
    /*Condicion para validar que el monto a pagar de la cobertura no sea mayor al monto parametrizado Miguel A. Carrion 14/10/2021*/
                                      IF FONOS_ROW.MON_PAG > V_MONTO_COBER AND F_VALIDA_EME_COBERTURA_WEB(FONOS_ROW.COBERTURA, FONOS_ROW.COMPANIA) THEN
                                        DBMS_OUTPUT.PUT_LINE(' Entro validacion emergencia:-> ');
                                        ERROR := '1';
                                        VAR_COD_ERR := 5;
                                      END IF;
                                    END IF;
    /* Si el servicio es Alto costo, valida si el asegurado llego al tope de los 2 salario minimo y le otorga el porciento
                                    de cobertura al 100%, de no ser asi le otorga segun lo que tenga acumulado de co-pago Miguel A. Carrion 24/08/2020  */
                                    IF V_INSER = DBAPER.BUSCA_PARAMETRO('TIP_SERV_CONS_MEDI_0', 96) THEN
                                      P_LIMITAR_COPAGO_X_GRUPO_AC (FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, NVL(V_INTIP, FONOS_ROW.TIP_COB), VAR_TIP_A_USO, FONOS_ROW.ASEGURADO, NVL(FONOS_ROW.DEPENDIENTE, 0), FECHA_DIA, FONOS_ROW.MON_DED, FONOS_ROW.MON_PAG, V_SIMULTANEO, FONOS_ROW.MON_DED, FONOS_ROW.MON_PAG);
                                    ELSIF V_INSER = TO_NUMBER(PKG_GENERAL.F_OBTEN_PARAMETRO_SEUS('SERVICIO_RENAL', 96)) THEN
                                      P_LIMITAR_COPAGO_X_GRUPO_AC (FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_COB, VAR_TIP_A_USO, FONOS_ROW.ASEGURADO, NVL(FONOS_ROW.DEPENDIENTE, 0), FECHA_DIA, FONOS_ROW.MON_DED, FONOS_ROW.MON_PAG, V_SIMULTANEO, FONOS_ROW.MON_DED, FONOS_ROW.MON_PAG, FONOS_ROW.TIP_SER);
                                    END IF;
    /* Si el servicio es GMM le asgina el monto correspondiente segun su limite   Miguel A. Carrion 24/08/2020   */
                                    IF V_INSER = DBAPER.BUSCA_PARAMETRO('GMM', FONOS_ROW.COMPANIA) AND FONOS_ROW.MON_PAG > VALOR_MAX_GMM THEN
                                      FONOS_ROW.MON_DED := FONOS_ROW.MON_DED +(FONOS_ROW.MON_PAG - VALOR_MAX_GMM);
                                      FONOS_ROW.MON_PAG := VALOR_MAX_GMM;
                                    END IF;
    --
                                    MONTO_LABORATORIO := 0;
    --
                                    IF LIMITE_LABORATORIO IS NOT NULL AND LIMITE_LABORATORIO <> 0 THEN
    -- Si tiene limite monto maximo por tipo de cobertura, entonces procede a buscar monto acumulado  --

    /* ---------------------------------------------------------- */
    /* Valida:                                                    */
    /* 1-) Cobertura No Exceda el Monto a Pagar para Tipo de      */
    /*     Cobertura de Laboratorio y Rayos X en Ambulatorios.    */
    /* ---------------------------------------------------------- */
    /* -----------------------------------------------------------------------  */
    /* Obtiene la Fecha Inicial segun la Unidad de Tiempo                       */
    /* de monto maximo para determinar si ha excedido el Uso de la Cobertura.  */
    /* -----------------------------------------------------------------------  */
                                      T_FEC_INI := PAQ_MATRIZ_VALIDACIONES.DETERMINA_FECHA_RANGO(FECHA_DIA, VAR_FEC_INI, NULL, NULL, NULL, P_RAN_U_EXC, LIMITE_LABORATORIO, NVL(P_UNI_T_MAX, 365));
    /* ----------------------------------------------------------------------  */
    /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto maximo  */
    /* para determinar si ha excedido el Uso maximo de la Cobertura.          */
    /* ----------------------------------------------------------------------  */
                                      T_FEC_FIN := PAQ_MATRIZ_VALIDACIONES.DETERMINA_FECHA_RANGO_FIN(FECHA_DIA, VAR_FEC_INI, NULL, NULL, NULL, LIMITE_LABORATORIO, NVL(P_UNI_T_MAX, 365), P_RAN_U_EXC);
    /* Si la Fecha Fin es null, entonces sera igual */
    /* a la Fecha de Servicio.     */
                                      IF T_FEC_FIN IS NULL THEN
                                        T_FEC_FIN := FECHA_DIA;
                                      END IF;
    --
                                      MONTO_LABORATORIO := PAQ_MATRIZ_VALIDACIONES.VALIDAR_LAB_RAYOS(VAR_TIP_A_USO, COD_ASE, COD_DEP, FECHA_DIA, FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, VAR_ESTATUS_CAN, T_FEC_INI, T_FEC_FIN);
    --
                                      MONTO_LABORATORIO := MONTO_LABORATORIO + FONOS_ROW.MON_PAG;
                                      IF MONTO_LABORATORIO > LIMITE_LABORATORIO THEN
                                        ERROR := '1';
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                                          (PROCESO, VALIDACION, CODIGO_ERROR)
                                        VALUES
                                          ('VALIDATECOBERTURA', NULL, 20);*/
                                      END IF;
    --
                                    END IF; /*END LIMITE_LABORATORIO IS NOT NULL*/
    -- Htorres - 29/09/2019
    -- Monto maximo que se pueda otorgar para esa cobertura por canales
                                    IF NVL(VMON_MAX_COB_ORIGEN, 0) > 0 AND (FONOS_ROW.MON_PAG > VMON_MAX_COB_ORIGEN) THEN
                                      ERROR := '1';
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                                        (PROCESO, VALIDACION, CODIGO_ERROR)
                                      VALUES
                                        ('VALIDATECOBERTURA', NULL, 19);*/
                                    END IF;
    --
                                    IF ERROR IS NULL THEN
    /***************************************************/
    /*    Validar que el afiliado pueda reclamar en el plan del asegurado */
    /***************************************************/
    ----MCARRION COMENTADO PARA PROBAR
                                      IF FONOS_ROW.TIP_SER != 8 THEN
                                        ERROR1 := PAQ_MATRIZ_VALIDACIONES.VALIDAR_PLAN_AFILIADO(FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO);
                                      ELSE
                                        CAT_PLAN_ODON := VALIDAR_PLAN_AFILIADO_CAT(FONOS_ROW.PLAN, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, V_CATEGORIA, V_PROVEEDOR, FONOS_ROW.COMPANIA);
                                        IF NOT(CAT_PLAN_ODON) AND (NOT VALIDA_RECLAMANTE(FONOS_ROW.AFILIADO)) THEN
    --
                                          ERROR1 := FALSE;
    --
                                          DBMS_OUTPUT.PUT_LINE('FALSE:');
                                        ELSIF (NVL(V_SIMULTANEO, 'N') = 'S'
                                        OR FONOS_ROW.PLAN = 230) THEN
    --
                                          ERROR1 := TRUE;
    --
                                        END IF;
                                      END IF;
    ---MCARRION 26/06/2019
                                      RED_EXCEPCION_ODON := DBAPER.EXCEPCION_POLIZA_ODON(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.TIP_SER);
                                      IF RED_EXCEPCION_ODON THEN
    ----
                                        ERROR1 := TRUE;
    ----
                                      ELSIF CAT_PLAN_ODON AND FONOS_ROW.TIP_SER = 8 THEN
    ---
                                        ERROR1 := TRUE;
    ----
                                      END IF;
                                      IF ERROR1 THEN
    /***************************************************/
    /*    Validar coberturas mutuamente excluyente     */
    /***************************************************/
                                        ERROR := PAQ_MATRIZ_VALIDACIONES.VALIDA_COB_EXCLUYENTE(TRUE, VAR_ESTATUS_CAN, VAR_TIP_A_USO, COD_ASE, COD_DEP, FONOS_ROW.TIP_SER, FONOS_ROW.TIP_COB, FONOS_ROW.COBERTURA, FECHA_DIA, VAR_FEC_INI, FONOS_ROW.FEC_ING, PLA_STC_ROW.FRECUENCIA, PLA_STC_ROW.UNI_TIE_F, FONOS_ROW.PLAN);
                                        IF ERROR IS NULL THEN
    /***************************************************/
    /*    Validar Beneficio Maximo por Familia         */
    /***************************************************/
                                          ERROR1 := PAQ_MATRIZ_VALIDACIONES.VALIDAR_BENEFICIO_MAX(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, COD_ASE, FECHA_DIA, VAR_FEC_INI, FONOS_ROW.FEC_ING, FONOS_ROW.MON_PAG, NULL);
                                          IF ERROR1 THEN
                                            DBMS_OUTPUT.PUT_LINE('Paq_Matriz_Validaciones.Validar_Beneficio_Max: '
                                              || 2);
                                          END IF;
                                          IF NOT (ERROR1) THEN
    /* --------------------------------------------- */
    /* Valida que el Monto Maximo digitado no exceda */
    /* el especificado en la Cobertura, solo para farmacias. */
    /* --------------------------------------------- */
                                            IF (FONOS_ROW.MON_REC_AFI IS NOT NULL
                                            AND FONOS_ROW.MON_REC_AFI <> 0) AND (PLA_STC_ROW.MON_MAX IS NOT NULL
                                            AND PLA_STC_ROW.MON_MAX <> 0) THEN
                                              IF (NVL(DSP_MON_PAG_ACUM, 0) + FONOS_ROW.MON_PAG) < PLA_STC_ROW.MON_MAX THEN
                                                VAR_CODE := 0;
                                              ELSE
                                                FONOS_ROW.MON_REC_AFI := PLA_STC_ROW.MON_MAX - DSP_MON_PAG_ACUM;
                                                VAR_CODE := 2;
    ---- CAPTURA ERROR
                                                INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA (
                                                  PROCESO,
                                                  VALIDACION,
                                                  CODIGO_ERROR,
                                                  PARAMETROS
                                                ) VALUES(
                                                  'VALIDATECOBERTURA',
                                                  '(NVL(DSP_MON_PAG_ACUM, 0) + FONOS_ROW.MON_PAG) < PLA_STC_ROW.MON_MAX)',
                                                  1,
                                                  DSP_MON_PAG_ACUM
                                                    ||' '
                                                    ||FONOS_ROW.MON_PAG
                                                    ||' '
                                                    ||PLA_STC_ROW.MON_MAX
                                                );
    ---- FIN CAPTURA ERROR
                                              END IF;
                                            ELSE
                                              VAR_CODE := 0;
                                            END IF;
                                          ELSE
                                            VAR_CODE := 2;
                                            DBMS_OUTPUT.PUT_LINE('VAR_CODE_1 :  '
                                              ||VAR_CODE);
    ---- CAPTURA ERROR
                                            INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA (
                                              PROCESO,
                                              VALIDACION,
                                              CODIGO_ERROR,
                                              PARAMETROS
                                            ) VALUES(
                                              'VALIDATECOBERTURA',
                                              'Paq_Matriz_Validaciones.Validar_Beneficio_Max',
                                              3,
                                              FONOS_ROW.COMPANIA
                                                ||' '
                                                ||FONOS_ROW.RAMO
                                                ||' '
                                                ||FONOS_ROW.SECUENCIAL
                                                ||' '
                                                ||FONOS_ROW.PLAN
                                                ||' '
                                                ||COD_ASE
                                                ||' '
                                                ||FECHA_DIA
                                                ||' '
                                                ||VAR_FEC_INI
                                                ||' '
                                                ||FONOS_ROW.FEC_ING
                                                ||' '
                                                ||FONOS_ROW.MON_PAG
                                            );
    ---- FIN CAPTURA ERROR
                                          END IF;
                                        ELSE
                                          VAR_CODE := 2;
                                          DBMS_OUTPUT.PUT_LINE('VAR_CODE_2 :  '
                                            ||VAR_CODE);
    ---- CAPTURA ERROR
                                          INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA (
                                            PROCESO,
                                            VALIDACION,
                                            CODIGO_ERROR,
                                            PARAMETROS
                                          ) VALUES(
                                            'VALIDATECOBERTURA',
                                            'Paq_Matriz_Validaciones.Valida_Cob_Excluyente',
                                            4,
                                            VAR_ESTATUS_CAN
                                              ||' '
                                              ||VAR_TIP_A_USO
                                              ||' '
                                              ||COD_ASE
                                              ||' '
                                              ||COD_DEP
                                              ||' '
                                              ||FONOS_ROW.TIP_SER
                                              ||' '
                                              ||FONOS_ROW.TIP_COB
                                              ||' '
                                              ||FONOS_ROW.COBERTURA
                                              ||' '
                                              ||FECHA_DIA
                                              ||' '
                                              ||VAR_FEC_INI
                                              ||' '
                                              ||FONOS_ROW.FEC_ING
                                              ||' '
                                              ||PLA_STC_ROW.FRECUENCIA
                                              ||' '
                                              ||PLA_STC_ROW.UNI_TIE_F
                                              ||' '
                                              ||FONOS_ROW.PLAN
                                          );
    ---- FIN CAPTURA ERROR
                                        END IF;
                                      ELSE
                                        VAR_CODE := 2;
                                        DBMS_OUTPUT.PUT_LINE('VAR_CODE_3 :  '
                                          ||VAR_CODE);
    ---- CAPTURA ERROR
                                        INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA (
                                          PROCESO,
                                          VALIDACION,
                                          CODIGO_ERROR,
                                          PARAMETROS
                                        ) VALUES(
                                          'VALIDATECOBERTURA',
                                          'DBAPER.EXCEPCION_POLIZA_ODON',
                                          5,
                                          FONOS_ROW.COMPANIA
                                            ||' '
                                            ||FONOS_ROW.RAMO
                                            ||' '
                                            ||FONOS_ROW.SECUENCIAL
                                            ||' '
                                            ||FONOS_ROW.TIP_SER
                                        );
    ---- FIN CAPTURA ERROR
                                      END IF;
                                    ELSE
                                      VAR_CODE := 2;
    /*Condicion para asignar el codigo de error que corresponde al cuando exceden el limite parametrizado
                                        Miguel A. Carrion FCCM  15/10/2021*/
                                      IF VAR_COD_ERR IS NOT NULL THEN
    --
                                        VAR_CODE := VAR_COD_ERR;
    --
                                      END IF;
                                      DBMS_OUTPUT.PUT_LINE('VAR_CODE_4 :  '
                                        ||VAR_CODE);
    ---- CAPTURA ERROR
                                      INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA (
                                        PROCESO,
                                        VALIDACION,
                                        CODIGO_ERROR,
                                        PARAMETROS
                                      ) VALUES(
                                        'VALIDATECOBERTURA',
                                        'VAR_CODE_4',
                                        6,
                                        VMON_MAX_COB_ORIGEN
                                          ||' '
                                          ||FONOS_ROW.MON_PAG
                                          ||' '
                                          ||VMON_MAX_COB_ORIGEN
                                      );
    ---- FIN CAPTURA ERROR
                                    END IF;
                                  ELSE
    -- del plan tipo de cobertura paralelo
                                    VAR_CODE := 2;
                                    DBMS_OUTPUT.PUT_LINE('VAR_CODE_5 :  '
                                      ||VAR_CODE);
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                                      (PROCESO, VALIDACION, CODIGO_ERROR)
                                    VALUES
                                      ('VALIDATECOBERTURA', NULL, 6);*/
                                  END IF;
                                ELSE
                                  VAR_CODE := 2;
                                  DBMS_OUTPUT.PUT_LINE('VAR_CODE_6 :  '
                                    ||VAR_CODE);
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                                    (PROCESO, VALIDACION, CODIGO_ERROR)
                                  VALUES
                                    ('VALIDATECOBERTURA', NULL, 7);*/
                                END IF;
                              ELSE
                                VAR_CODE := 2;
                                DBMS_OUTPUT.PUT_LINE('VAR_CODE_7 :  '
                                  ||VAR_CODE);
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                                  (PROCESO, VALIDACION, CODIGO_ERROR)
                                VALUES
                                  ('VALIDATECOBERTURA', NULL, 8);*/
                              END IF;
                            ELSE
                              VAR_CODE := 2;
                              DBMS_OUTPUT.PUT_LINE('VAR_CODE_8 :  '
                                ||VAR_CODE);
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                                (PROCESO, VALIDACION, CODIGO_ERROR)
                              VALUES
                                ('VALIDATECOBERTURA', NULL, 9);*/
                            END IF;
                          ELSE
                            VAR_CODE := 2;
                            DBMS_OUTPUT.PUT_LINE('VAR_CODE_9 :  '
                              ||VAR_CODE);
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                              (PROCESO, VALIDACION, CODIGO_ERROR)
                            VALUES
                              ('VALIDATECOBERTURA', NULL, 10);*/
                          END IF;
                        ELSE
                          VAR_CODE := 2;
                          DBMS_OUTPUT.PUT_LINE('VAR_CODE_10 :  '
                            ||VAR_CODE);
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                            (PROCESO, VALIDACION, CODIGO_ERROR)
                          VALUES
                            ('VALIDATECOBERTURA', NULL, 11);*/
                        END IF;
                      ELSE
                        VAR_CODE := 2;
                        DBMS_OUTPUT.PUT_LINE('VAR_CODE_11 :  '
                          ||VAR_CODE);
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                          (PROCESO, VALIDACION, CODIGO_ERROR)
                        VALUES
                          ('VALIDATECOBERTURA', ERROR, 12);*/
                      END IF;
                    ELSE
                      VAR_CODE := 2;
                      DBMS_OUTPUT.PUT_LINE('VAR_CODE_12 :  '
                        ||VAR_CODE);
                    END IF;
                  ELSE
                    VAR_CODE := 3;
                  END IF;
                ELSE
                  VAR_CODE := F_OBTEN_PARAMETRO_SEUS('HOMOLOGACION_ERROR', FONOS_ROW.COMPANIA); /**Homologacion de coberturas / Jestepan 30/08/2022 **/
                END IF;
              ELSE
                VAR_CODE := 1;
              END IF;
            END IF;
    --<84770> jdeveaux --> Si es un plan internacional se debe ir por el proceso internacional
          ELSE
            V_INTERNACIONAL := 'S';
          END IF;
    --</84770>
        ELSE
          VAR_CODE := 1;
        END IF;
        IF VAR_CODE = 0 THEN
    -- Para verificar si no hay ningun error
    -- VALIDAR_COBERTURA: Funcion para controlar la cobertura 2836 ------------------------------
    -- * Esta cobertura solo estara disponible en horario de 6:00 pm a 6:00 am
    -- * Las clinicas paquetes no deben reclamar por esta cobertura
    -- * Los medicos categoria A+ (Platinum) estan excepto de estas validaciones
    -- * Las excepciones deben poder ser manejadas por un superusuario
    -- * Para que el medico pueda reclamar el servicio el asegurado debe tener
    --   una reclamacion del mismo servicio (EMERGENCIA) por lo menos de 72 horas de antelacion.
    ---------------------------------------------------------------------------------------------

    /*
                  IF FONOS_ROW.COBERTURA = 2836 THEN
                    IF SUBSTR(VALIDAR_COBERTURA(vUSUARIO, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, FONOS_ROW.TIP_SER, 2836, SYSDATE, COD_DEP, COD_ASE), 1, 1) != '0' THEN
                      VAR_CODE := 2;
                    END IF;
                END IF;
                -- Validar cobertura 2836
            */
          IF FONOS_ROW.TIP_SER <> 3 THEN
    -- SERVICIO DE EMERGENCIA
    -- Suspencion por Suplantacion (Fraude)
            MFRAUDE := 'N';
    -- para verificar si el afiliado tiene una marca de suspencion del servicio de salud
            OPEN C_FRAUDE;
            FETCH C_FRAUDE INTO MFRAUDE;
            CLOSE C_FRAUDE;
            IF MFRAUDE = 'S' THEN
              VAR_CODE := 2; -- VAR_CODE := 2;
              DBMS_OUTPUT.PUT_LINE('VAR_CODE_14 :  '
                ||VAR_CODE);
    /*INSERT INTO DBAPER.LOG_PKG_INFOX_HTPA
                  (PROCESO, VALIDACION, CODIGO_ERROR)
                VALUES
                  ('VALIDATECOBERTURA', NULL, 17);*/
            END IF;
    -- Fraude
          END IF;
        END IF; -- IF VAR_CODE <> 0 THEN
    --
    --<JDEVEAUX 18MAY2016>
    --Se restauran nuevamente los valores de la poliza voluntaria antes de salir de VALIDATECOBERTURA
        IF V_SEC_ORI IS NOT NULL THEN
          FONOS_ROW.PLAN := V_PLAN_ORI;
          FONOS_ROW.COMPANIA := V_COMPANIA_ORI;
          FONOS_ROW.RAMO := V_RAMO_ORI;
          FONOS_ROW.SECUENCIAL := V_SEC_ORI;
        END IF;
    --</jdeveaux>
    ---Enfoco mcarrion 25/02/2019
        IF V_COD_ERROR IS NOT NULL THEN
          VAR_CODE := V_COD_ERROR;
        END IF;
        FONOS_ROW.MON_PAG := ROUND(FONOS_ROW.MON_PAG, 2);
        NO_M_COB_ROW.LIMITE := ROUND(NO_M_COB_ROW.LIMITE, 2);
        FONOS_ROW.POR_COA := ROUND(POR_COA, 2);
        FONOS_ROW.MON_DED := ROUND(FONOS_ROW.MON_DED, 2);
    --
        UPDATE INFOX_SESSION
        SET
          CODE = VAR_CODE,
          TIP_SER = FONOS_ROW.TIP_SER,
          TIP_COB = FONOS_ROW.TIP_COB,
          R_TIP_COB = FONOS_ROW.TIP_COB,
          MON_REC = NO_M_COB_ROW.LIMITE,
          MON_PAG = FONOS_ROW.MON_PAG,
          POR_COA = FONOS_ROW.POR_COA,
          DES_COB = COB_SAL_ROW.DESCRIPCION,
          MON_REC_AFI = FONOS_ROW.MON_REC_AFI,
          COBERTURA = FONOS_ROW.COBERTURA,
          MON_DED = FONOS_ROW.MON_DED,
          COBERTURASTR = P_INSTR1
        WHERE
          CURRENT OF A;
        CLOSE A;
    --
        IF NVL(V_INTERNACIONAL, 'N') = 'S' THEN
          P_VALIDATECOBERTURA_INT(P_NAME, P_NUMSESSION, P_INSTR1, P_INSTR2, P_INNUM1, P_INNUM2, P_OUTSTR1, P_OUTSTR2, P_OUTNUM1, P_OUTNUM2);
          VAR_CODE := P_OUTNUM1;
    ---
          FONOS_ROW.MON_PAG := TO_NUMBER(P_OUTSTR1);
          NO_M_COB_ROW.LIMITE := TO_NUMBER(P_OUTSTR1);
          FONOS_ROW.MON_DED := NVL(TO_NUMBER(P_OUTSTR2), 0);
        END IF;
    --
        P_OUTSTR1 := LTRIM(TO_CHAR(FONOS_ROW.MON_PAG, '999999990.00'));
        P_OUTSTR2 := LTRIM(TO_CHAR(FONOS_ROW.MON_DED, '999999990.00'));
        P_OUTNUM1 := VAR_CODE;
    --
        IF VMESSAGE IS NOT NULL THEN
          P_OUTSTR1 := LTRIM(TO_CHAR(V_MONPAG_DEVUELVE_FUNCION, '999999990.00'));
          P_OUTSTR2 := LTRIM(TO_CHAR(FONOS_ROW.MON_PAG, '999999990.00'));
    --      P_OUTSTR2 := ltrim(to_char(V_MONTO_RECLAMADO_GRUPO, '999999990.00'))-ltrim(to_char(fonos_row.mon_pag, '999999990.00'));---ltrim(to_char(fonos_row.mon_ded, '999999990.00'));
          P_OUTNUM1 := VAR_CODE;
          P_OUTNUM2 := '5';
        END IF;
      END;
    END;
  --
  -- --<84770> jdeveaux --> PROCESO PARA VALIDAR COBERTURA PARA PLANES INTERNACIONALES
  -- procedure inserta una cobertura en la reclamacion abierta por open reclamacion --
  -- 0->ok 1-> error --
  PROCEDURE P_VALIDATECOBERTURA_INT(p_name       IN VARCHAR2,
                                    p_numsession IN NUMBER,
                                    p_instr1     IN VARCHAR2,
                                    p_instr2     IN VARCHAR2,
                                    p_innum1     IN NUMBER,
                                    p_innum2     IN NUMBER,
                                    p_outstr1    OUT VARCHAR2,
                                    p_outstr2    OUT VARCHAR2,
                                    p_outnum1    OUT NUMBER,
                                    p_outnum2    OUT NUMBER) IS
  BEGIN
    /* @% Verificar Disponibilidad de Cobertura */
    /* Descripcion : Valida que el Afiliado  pueda ofrecer la cobertura y que el asegurado*/
    /*               pueda recibir la cobertura. */
    DECLARE
      DUMMY            VARCHAR2(1);
      ERROR            CHAR(1);
      ERROR1           BOOLEAN; /*  Se utiliza igual que ERROR, pero es enviada en algunos casos que la funcion devuelve boolean */
      VAR_CODE         NUMBER(2) := 1;
      FONOS_ROW        INFOX_SESSION%ROWTYPE;
      SER_SAL_ROW      SER_SAL%ROWTYPE;
      TIP_C_SAL_ROW    TIP_C_SAL%ROWTYPE;
      COB_SAL_ROW      COB_SAL%ROWTYPE;
      NO_M_COB_ROW     NO_M_COB%ROWTYPE;
      DES_TIP_N_MED    TIPO_NO_MEDICO.DESCRIPCION%TYPE;
      COD_ASE          NUMBER(11);
      COD_DEP          NUMBER(3);
      VAR_TIP_SER2     SER_SAL.CODIGO%TYPE;
      FECHA_DIA        DATE;
      POR_COA          POL_P_SER.POR_COA%TYPE;
      PLA_STC_ROW      PLA_STC%ROWTYPE;
      VAR_ESTATUS_CAN  RECLAMACION.ESTATUS%TYPE := 183;
      VAR_TIP_A_USO    RECLAMACION.TIP_A_USO%TYPE;
      VAR_FEC_INI      POLIZA.FEC_INI%TYPE;
      VAR_FEC_FIN      POLIZA.FEC_FIN%TYPE;
      T_FEC_INI        POLIZA.FEC_INI%TYPE;
      T_FEC_FIN        POLIZA.FEC_FIN%TYPE;
      DSP_COB_LAB      NUMBER;
      DSP_FREC_TIP_COB NUMBER;
      DSP_FREC_ACUM    NUMBER;
      DSP_MON_PAG_ACUM NUMBER;
      SEC_RECLAMACION  RECLAMACION.SECUENCIAL%TYPE;
      MONTO_CONTRATADO VARCHAR(1);
      /* Parametro para saber si la cobertura esta contratada con  */
      /* el reclamante o con la poliza (ej. habitacion y medicina) */
      MONTO_LABORATORIO  NUMBER(11, 2);
      VAR_CATEGORIA      VARCHAR2(40);
      P_DSP_CATEGORIA    PLA_STC.CATEGORIA%TYPE;
      P_DSP_EST_CIV      PLA_STC.EST_CIV%TYPE;
      LIMITE_LABORATORIO LIM_C_REC.MON_MAX%TYPE;
      P_MON_EXE          LIM_C_REC.MON_E_COA%TYPE;
      P_UNI_T_EXE        LIM_C_REC.UNI_TIE_E%TYPE;
      P_UNI_T_MAX        LIM_C_REC.UNI_TIE_M%TYPE;
      P_RAN_EXE          LIM_C_REC.RAN_U_EXC%TYPE;
      P_POR_COA          LIM_C_REC.POR_COA%TYPE;
      P_MON_ACUM         NUMBER(14, 2);
      ORI_FLAG           VARCHAR2(1);
      V_INSER            NUMBER(2);
      V_INTIP            NUMBER(3);
      V_INCOB            VARCHAR2(10);
      P_MONTO_MAX        NUMBER(11, 2);
      var_frecuencia     number(3) := 1;
      var_uni_tie_f      PLA_STC_ROW.UNI_TIE_F%type;
      var_dsp_frec_acum  DSP_FREC_ACUM%type;

      vMON_MAX_COB_ORIGEN NUMBER(11, 2);

      -- Varaibles provisionales--
      V_MON_DED_TIP_COB NUMBER(14, 2);
      V_MOD_A_DED       VARCHAR2(1 BYTE);
      V_UNI_TIE_DED     NUMBER(3);
      V_RAN_U_DED       VARCHAR2(3 BYTE);
      V_FOR_M_EXC       VARCHAR2(1 BYTE);
      V_CAL_COP_RANG    VARCHAR2(10);
      V_NO_APL_SER      VARCHAR2(10);
      VAR_PLAN          NUMBER(4);
      VAR_TIPO          VARCHAR2(20);
      VAR_SECUENCIAL    NUMBER(8);
      v_error_handler   varchar2(500);
      var_deducible     number;
      dsp_fec_ing       date;

      --<84770> DMENENES 29JUN2015
      --Variables para procesos de Salud Internacional
      V_MON_MAX       NUMBER;
      V_DIAS_TIP_COB  NUMBER;
      V_MON_DISP_TC   NUMBER;
      V_VAR_IND_DED   VARCHAR2(10) := 'S'; -- agregado para mirex
      V_APL_DED_RIE   VARCHAR2(10);
      V_IND_DED_RIE   VARCHAR2(10);
      V_FEC_I_CAR     DATE;
      V_FEC_F_CAR     DATE;
      V_IND_DED_CAS   VARCHAR2(10) := 'N';
      V_NUMERO_CASO   NUMBER;
      V_ACUM_REC_G    NUMBER;
      V_valida_limite VARCHAR2(10);
      vafiliado_SAL   NUMBER;
      DSP_UNI_TIE_F   NUMBER;
      VAR_UNI_T_EXE   NUMBER;
      DSP_TIE_ESP     NUMBER;
      DSP_UNI_T_ESP   NUMBER;

      VAR_MON_E_COA number;
      VAR_FOR_E_COA varchar2(10);
      VAR_MON_R_DED number;
      VAR_MON_COA   number;
      --</84770>

      --Enfoco mcarrion 12/02/2019
      v_prov_capitado NUMBER(1) := 0;
      v_prov_basico   NUMBER;
      v_prov_existe   NUMBER;
      v_nuevo         VARCHAR2(1);
      --Enfoco mcarrion 12/02/2019
      v_mon_rec_dg   NUMBER;
      v_reserva     NUMBER;
      VAR_MOD_A_DED varchar2(10);
      VMON_PAG_TC    NUMBER;
      VMON_FEE_TC   NUMBER;
      VMON_FEE      NUMBER;
      VFLAG_DEL_COB  VARCHAR2(10);
      V_MSG          VARCHAR2(100);
      V_RED_PLAT     NUMBER(3);
      -- Technocons
      mFRAUDE VARCHAR(1);
      --
      M_PLAN_EXCEPTION VARCHAR2(4000);
      --
      M_VALIDA_PLAN VARCHAR2(4000);
      V_GRUPO       VARCHAR2(5);
      V_MIREX       NUMBER := TO_NUMBER(DBAPER.BUSCA_PARAMETRO('PLAN_MIREX',FONOS_ROW.COMPANIA));
      --
      V_MONTO_ACUMULADO_COBER NUMBER; -- MONTO ACUMULADO DE TODAS LAS COBERTURAS DE UNA RECLAMACION.
      --
      P_RAN_U_EXC LIM_C_REC.RAN_U_EXC%TYPE;
      P_RAN_U_MAX LIM_C_REC.RAN_U_EXC%TYPE;
      --
      vESTUDIO_REPETICION VARCHAR2(1) := 'N';

     ------------------
     v_proveedor_int number;
     v_categoria_int number;

      CURSOR C_PLAN_EXCEPTION IS
        SELECT VALPARAM
          FROM TPARAGEN D
         WHERE NOMPARAM IN ('LIB_PLAN_FONO')
           AND COMPANIA = FONOS_ROW.COMPANIA;
      --
      CURSOR C_VALIDA_PLAN_EXCENTO(MPLAN VARCHAR2, M_LISTA_PLAN VARCHAR2) IS
        SELECT COLUMN_VALUE
          FROM TABLE(SPLIT(M_LISTA_PLAN))
         WHERE COLUMN_VALUE = MPLAN;
      --
      CURSOR A IS
        SELECT TIP_REC,
               AFILIADO,
               TIP_COB,
               COBERTURA,
               COMPANIA,
               RAMO,
               SECUENCIAL,
               PLAN,
               ASEGURADO,
               DEPENDIENTE,
               SEXO,
               FEC_ING,
               FEC_NAC,
               ANO_REC,
               SEC_REC,
               CATEGORIA,
               EST_CIV,
               MON_REC_AFI,
               CAT_N_MED,
               TIP_SER
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION;
      --
      CURSOR B IS
        SELECT TIP_N_MED.DESCRIPCION
          FROM NO_MEDICO, TIPO_NO_MEDICO TIP_N_MED
         WHERE NO_MEDICO.CODIGO = FONOS_ROW.AFILIADO
           AND TIP_N_MED.CODIGO = NO_MEDICO.TIP_N_MED;
      --
      CURSOR C IS
        SELECT POLIZA15.FEC_INI, POLIZA15.FEC_FIN
          FROM POLIZA POLIZA15
         WHERE POLIZA15.COMPANIA = FONOS_ROW.COMPANIA
           AND POLIZA15.RAMO = FONOS_ROW.RAMO
           AND POLIZA15.SECUENCIAL = FONOS_ROW.SECUENCIAL
           AND POLIZA15.FEC_VER =
               (SELECT MAX(FEC_VER)
                  FROM POLIZA POLIZA2
                 WHERE POLIZA2.COMPANIA = POLIZA15.COMPANIA
                   AND POLIZA2.RAMO = POLIZA15.RAMO
                   AND POLIZA2.SECUENCIAL = POLIZA15.SECUENCIAL
                      --AND TRUNC(POLIZA2.FEC_VER) <= FECHA_DIA);
                   AND POLIZA2.FEC_VER < TRUNC(FECHA_DIA) + V_1 --*--
                );

      CURSOR D IS
        SELECT DESCRIPCION
          FROM CATEGORIA_ASEGURADO
         WHERE CODIGO = FONOS_ROW.CATEGORIA;
      --
      CURSOR C_COBERTURA IS
        SELECT '1'
          FROM COB_SAL
         WHERE CODIGO = TO_NUMBER(FONOS_ROW.COBERTURA);

      -- Technocons * Victor Acevedo
      CURSOR C_FRAUDE IS
        SELECT FRAUDE
          FROM MOTIVO_ASE_DEP
         WHERE ASEGURADO = COD_ASE
           AND DEPENDIENTE = NVL(COD_DEP, 0)
           AND FRAUDE = V_S;

      CURSOR C_NUMPLA(P_COD_ASE NUMBER, P_COD_DEP NUMBER) IS
        Select NUM_PLA
          from afiliado_plasticos afi_pla
         where afi_pla.asegurado = p_cod_ase
           and afi_pla.secuencia = p_cod_dep
           and afi_pla.fec_ver =
               (select max(z.fec_ver)
                  from afiliado_plasticos z
                 where z.asegurado = afi_pla.asegurado
                   and z.secuencia = afi_pla.secuencia
                   and z.fec_ver < trunc(sysdate) + v_1)
           and afi_pla.fec_u_act =
               (select max(z.fec_u_act) d
                  from afiliado_plasticos z
                 where z.asegurado = afi_pla.asegurado
                   and z.secuencia = afi_pla.secuencia
                   and z.fec_ver = afi_pla.fec_ver);

      v_num_pla number;
      --
      --TP 09/11/2018 Enfoco
      cursor cat_medico(vreclamante number) is
        select codigo
          from medico a
         where codigo = vreclamante
           and exists (select 1
                  from med_esp_v b
                 where a.codigo = b.medico
                   and b.especialidad = V_229); --*--

      cursor cat_n_med(vreclamante number) is
        select codigo
          from no_medico
         where codigo = vreclamante
           and tip_n_med = V_6; --*--

      v_cat number;
      --
      --TP 09/11/2018 Enfoco
      ---Enfoco mcarrion 12/02/2019
      CURSOR cur_prov_capitado IS
        Select valor_capita, afiliado
          From POLIZA_PROVEDOR p, no_medico n
         Where p.compania = FONOS_ROW.COMPANIA
           And p.ramo = FONOS_ROW.RAMO
           And p.secuencial = FONOS_ROW.SECUENCIAL
           And p.servicio = FONOS_ROW.TIP_SER
           And p.plan = FONOS_ROW.PLAN
           And n.codigo = P.AFILIADO
           And N.VALOR_CAPITA = V_1
           And p.estatus = V_46
           And p.fec_ver = (Select max(fec_ver)
                              From POLIZA_PROVEDOR a
                             Where A.COMPANIA = p.compania
                               And a.ramo = p.ramo
                               And a.secuencial = p.secuencial
                               And a.plan = p.plan);

      Cursor cap_basico(p_proveedor number) is
        Select 1
          From plan_afiliado
         Where plan = V_230 --*--
           And afiliado = p_proveedor
           And servicio = V_8 --*--
           And tip_afi IN (V_NO_MEDICO, V_MEDICO); --*--

      Cursor nuevo(vreclamante number) is
        Select 'S'
          From Plan_Dental_nuevo p
         Where p.tip_afi = V_NO_MEDICO --*--
           And p.afiliado = vreclamante
           And p.nuevo = V_S;

      VDSP_FEC_ING DATE;
      EDAD_ASE     NUMBER;
      --
      CURSOR Cur_Ase IS
        SELECT FEC_ING
          FROM ASEGURADO
         WHERE CODIGO = vafiliado_SAL;
      --
      CURSOR Cur_Dep IS
        SELECT FEC_ING
          FROM DEPENDIENTE
         WHERE CODIGO = vafiliado_SAL;
      --
  ----Proceso Integracion de categoria a polizas Internacionales para planes Odontologicos tmm 7-7-2021

-----------------------

      CURSOR cur_cat_prov IS
        select a.afiliado, a.cat_pro
          from pol_pro a
         where compania = FONOS_ROW.COMPANIA
           and ramo = FONOS_ROW.RAMO
           and secuencial = FONOS_ROW.SECUENCIAL
           and plan = FONOS_ROW.PLAN
           and servicio = FONOS_ROW.TIP_SER
           and estatus = V_46
           and fec_ver = (select max(b.fec_ver)
                            FROM poliza_provedor b
                           WHERE a.compania = b.compania
                             AND a.ramo = b.ramo
                             AND a.secuencial = b.secuencial
                             AND a.plan = b.plan
                             AND a.tip_afi = b.tip_afi
                             AND a.afiliado = b.afiliado
                             AND a.servicio = b.servicio
                             );



      /* FUNCION para  Buscar Datos de la Cobertura */
      FUNCTION BUSCAR_DATOS_COBERTURA(VAR_TIP_SER    IN INFOX_SESSION.TIP_SER%TYPE,
                                      VAR_COBERTURA  IN INFOX_SESSION.COBERTURA%TYPE,
                                      VAR_TIP_REC    IN INFOX_SESSION.TIP_REC%TYPE,
                                      VAR_RECLAMANTE IN INFOX_SESSION.AFILIADO%TYPE,
                                      VAR_TIP_SER2   IN OUT INFOX_SESSION.TIP_SER%TYPE,
                                      VAR_TIP_COB    IN OUT REC_C_SAL.TIP_COB%TYPE,
                                      VAR_DSP4       IN OUT SER_SAL.DESCRIPCION%TYPE,
                                      VAR_DSP2       IN OUT TIP_C_SAL.DESCRIPCION%TYPE,
                                      VAR_DSP3       IN OUT COB_SAL.DESCRIPCION%TYPE,
                                      NO_M_LIM_AFI   IN OUT NO_M_COB.LIMITE%TYPE,
                                      NO_M_POR_DES   IN OUT NO_M_COB.POR_DES%TYPE)

       RETURN NUMBER IS
        ERROR CHAR(1) := NULL;
      BEGIN
        p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

        IF FONOS_ROW.TIP_REC = 'ASEGURADO' THEN
          ERROR := Paq_Matriz_Validaciones.Datos_Cobertura_Asegurados(var_tip_ser,
                                                                      var_cobertura,
                                                                      var_tip_ser2,
                                                                      var_tip_cob,
                                                                      var_dsp4,
                                                                      var_dsp2,
                                                                      var_dsp3);

        ELSIF FONOS_ROW.TIP_REC = 'NO_MEDICO' THEN
          ERROR := Paq_Matriz_Validaciones.Datos_Cobertura_No_Medico(FONOS_ROW.COMPANIA,
                                                                     FONOS_ROW.RAMO,
                                                                     FONOS_ROW.SECUENCIAL,
                                                                     var_reclamante,
                                                                     var_tip_ser,
                                                                     fonos_row.PLAN,
                                                                     var_cobertura,
                                                                     var_tip_ser2,
                                                                     var_tip_cob,
                                                                     var_dsp4,
                                                                     var_dsp2,
                                                                     var_dsp3,
                                                                     no_m_lim_afi,
                                                                     no_m_por_des);

        ELSIF FONOS_ROW.TIP_REC = 'MEDICO' THEN
          ERROR := Paq_Matriz_Validaciones.Datos_Cobertura_Medico(FONOS_ROW.COMPANIA,
                                                                  FONOS_ROW.RAMO,
                                                                  FONOS_ROW.SECUENCIAL,
                                                                  var_reclamante,
                                                                  --VAR_CAT_N_MED,
                                                                  var_tip_ser,
                                                                  fonos_row.PLAN,
                                                                  var_cobertura,
                                                                  var_tip_ser2,
                                                                  var_tip_cob,
                                                                  var_dsp4,
                                                                  var_dsp2,
                                                                  var_dsp3,
                                                                  no_m_lim_afi,
                                                                  no_m_por_des);

        END IF;
        RETURN(ERROR);
      END;
      --
      PROCEDURE Calcular_Reserva(LIM_AFI     IN NO_M_COB.LIMITE%TYPE,
                                 POR_DES     IN NO_M_COB.POR_DES%TYPE,
                                 POR_COA     IN POL_P_SER.POR_COA%TYPE,
                                 MON_PAG     IN OUT REC_C_SAL.MON_PAG%TYPE,
                                 MON_POR_COA IN OUT INFOX_SESSION.MON_PAG%TYPE,
                                 P_MON_EXE   IN NUMBER,


                                 P_MON_ACUM IN NUMBER) IS
      BEGIN
        IF P_MON_EXE IS NOT NULL AND P_MON_EXE <> 0 THEN
          IF P_MON_ACUM > P_MON_EXE THEN
            MON_POR_COA := ROUND((LIM_AFI * POR_COA / 100), 2);
          ELSIF (P_MON_ACUM + LIM_AFI) > P_MON_EXE THEN
            MON_POR_COA := ROUND(((((LIM_AFI + P_MON_ACUM) - P_MON_EXE) *
                                 POR_COA) / 100),
                                 2);
          END IF;
          MON_PAG := (LIM_AFI - NVL(MON_POR_COA, 0));
        ELSE
          MON_POR_COA := ROUND((LIM_AFI * POR_COA / 100), 2);
          MON_PAG     := (LIM_AFI - NVL(MON_POR_COA, 0));
        END IF;
      END;
      /* Rutina Principal */

    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      --
      fecha_dia := TO_DATE(TO_CHAR(SYSDATE, 'dd/mm/yyyy'), 'dd/mm/yyyy');
      OPEN A;
      FETCH A
        INTO FONOS_ROW.TIP_REC,
             FONOS_ROW.AFILIADO,
             FONOS_ROW.TIP_COB,
             FONOS_ROW.COBERTURA,
             FONOS_ROW.COMPANIA,
             FONOS_ROW.RAMO,
             FONOS_ROW.SECUENCIAL,
             FONOS_ROW.PLAN,
             FONOS_ROW.ASEGURADO,
             FONOS_ROW.DEPENDIENTE,
             FONOS_ROW.SEXO,
             FONOS_ROW.FEC_ING,
             FONOS_ROW.FEC_NAC,
             FONOS_ROW.ANO_REC,
             FONOS_ROW.SEC_REC,
             FONOS_ROW.CATEGORIA,
             FONOS_ROW.EST_CIV,
             FONOS_ROW.MON_REC_AFI,
             FONOS_ROW.CAT_N_MED,
             FONOS_ROW.TIP_SER;
      IF A%FOUND THEN
        OPEN D;
        FETCH D
          INTO VAR_CATEGORIA;
        CLOSE D;
        --
        COD_ASE := TO_NUMBER(FONOS_ROW.ASEGURADO);
        COD_DEP := TO_NUMBER(FONOS_ROW.DEPENDIENTE);
        --
        IF NVL(COD_DEP, 0) = 0 THEN
          VAR_TIP_A_USO := 'ASEGURADO';
        ELSE
          VAR_TIP_A_USO := 'DEPENDIENT';
        END IF;
        --
        IF FONOS_ROW.TIP_REC = 'NO_MEDICO' THEN
          OPEN B;
          FETCH B
            INTO DES_TIP_N_MED;
          CLOSE B;
        ELSE
          DES_TIP_N_MED := FONOS_ROW.TIP_REC;
        END IF;
        --
        OPEN C;
        FETCH C
          INTO VAR_FEC_INI, VAR_FEC_FIN;
        CLOSE C;
        --
        /*codigo nuevo*/
        V_INSER := TO_NUMBER(SUBSTR(P_INSTR1, 1, 2));
        V_INTIP := TO_NUMBER(SUBSTR(P_INSTR1, 3, 2));
        V_INCOB := SUBSTR(P_INSTR1, 5, 10);
        --

        IF V_INTIP = 6 THEN
          V_INSER := 8; --TP 09/11/2018 Enfoco
          --<00062> jdeveaux 27nov2017 Se valida la red dental del afiliado para determinar servicio
          /*V_RED_PLAT := DBAPER.F_VALIDA_RED_DENTAL_PLATINUM(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, V_MSG);
          IF  V_RED_PLAT = 8 THEN
               V_INSER :=  V_RED_PLAT;
          ELSE
               V_INSER := 1;
          END IF;*/
          --</00062>
        ELSIF V_INTIP > 7 AND V_INTIP <> 76 THEN
          V_INSER := 3;
        ELSE
          V_INSER := 1;
        END IF;
        --
        --TP 09/11/2018 Enfoco
        if FONOS_ROW.TIP_REC = 'MEDICO' then
          open cat_medico(FONOS_ROW.AFILIADO);
          fetch cat_medico
            into v_cat;
          if cat_medico%found then
            V_INSER := 8;
          end if;
          close cat_medico;
        else
          open cat_n_med(FONOS_ROW.AFILIADO);
          fetch cat_n_med
            into v_cat;
          if cat_n_med%found then
            V_INSER := 8;
          end if;
          close cat_n_med;
        end if;
        --TP 09/11/2018 Enfoco
        --SI AUN NO SE HA GENERADO UNA RECLAMACION TOMA EL SERVICIO DEL VALOR DIGITADO--
        --EN CASO CONTRARIO TOMA EL SERVICIO DE LA RECLAMACION YA INSERTADA--
        IF (NVL(FONOS_ROW.SEC_REC, 0) = 0) THEN
          FONOS_ROW.TIP_SER := V_INSER;
        END IF;
        --
        FONOS_ROW.TIP_COB   := V_INTIP;
        FONOS_ROW.COBERTURA := V_INCOB;
        var_tip_ser2        := FONOS_ROW.TIP_SER;
        --

        --Enfoco mcarrion 12/02/2019
        if FONOS_ROW.TIP_REC = 'NO_MEDICO' and FONOS_ROW.TIP_SER = 8       ---se agrego la validciona para los medicos en internacinal porque
        or FONOS_ROW.TIP_REC = 'MEDICO' and FONOS_ROW.TIP_SER = 8 then     ---porque si llevan un proveedor de odontologia

          OPEN cur_prov_capitado;
          FETCH cur_prov_capitado
            INTO v_prov_capitado, v_prov_basico;
          CLOSE cur_prov_capitado;
          --
          OPEN cap_basico(FONOS_ROW.AFILIADO);
          FETCH cap_basico
            INTO v_prov_existe;
          CLOSE cap_basico;
          --
          OPEN nuevo(v_prov_basico);
          FETCH nuevo
            into v_nuevo;
          CLOSE nuevo;
          --
          IF v_prov_capitado = 1 and NVL(v_prov_existe, 0) = 0 and
             nvl(v_nuevo, 'N') = 'N' then
            --
            var_code := 2; --MSG_ALERT('Afiliado tiene un plan capitado, o debe pasar reclamaciones.','E', TRUE);
            --

          ELSE
            ----Proceso Integracion de categoria a polizas Internacionales para planes Odontologicos tmm 7-7-2021
           IF ((FONOS_ROW.TIP_REC = 'NO_MEDICO' AND
                 FONOS_ROW.TIP_SER = 8) OR
                 (FONOS_ROW.TIP_REC = 'MEDICO' AND FONOS_ROW.TIP_SER = 8)) THEN

                OPEN cur_cat_prov;
                FETCH cur_cat_prov
                  INTO v_proveedor_int, v_categoria_int;
                CLOSE cur_cat_prov;

           END IF;
          END IF;

        END IF;
        ---Enfoco mcarrion 12/02/2019
        --
        IF nvl(COD_ASE, 0) = 0 THEN
          var_code := 1;
        END IF;
        --  IF VAR_CODE IS NULL OR VAR_CODE <> 2 THEN
        IF nvl(COD_ASE, 0) <> 0 THEN
          OPEN C_COBERTURA;
          FETCH C_COBERTURA
            INTO DUMMY;
          IF C_COBERTURA%NOTFOUND THEN
            ERROR := '1';
          END IF;
          CLOSE C_COBERTURA;
          --
          IF ERROR IS NULL THEN

            error := BUSCAR_DATOS_COBERTURA(FONOS_ROW.TIP_SER,
                                            FONOS_ROW.COBERTURA,
                                            FONOS_ROW.TIP_REC,
                                            FONOS_ROW.AFILIADO,
                                            VAR_TIP_SER2,
                                            FONOS_ROW.TIP_COB,
                                            SER_SAL_ROW.DESCRIPCION,
                                            TIP_C_SAL_ROW.DESCRIPCION,
                                            COB_SAL_ROW.DESCRIPCION,
                                            NO_M_COB_ROW.LIMITE,
                                            NO_M_COB_ROW.POR_DES);
            /*SYSDATE,
            FONOS_ROW.CAT_N_MED,
            DAT_ASEG_ROW
            );*/
            IF ERROR IS NULL THEN
              -- Enfoco - 05/11/2018
              Paq_Matriz_Validaciones.BUSCA_RANGOS_COBERTURA(FONOS_ROW.PLAN,
                                                             FONOS_ROW.TIP_SER,
                                                             FONOS_ROW.TIP_COB,
                                                             P_RAN_U_EXC,
                                                             P_RAN_U_MAX);
              /* ---------------------------------------------------------------------- */
              /*   Determina Origen de la Cobertura                                      */
              /* ---------------------------------------------------------------------- */
              --
              OPEN C_PLAN_EXCEPTION;
              FETCH C_PLAN_EXCEPTION
                INTO M_PLAN_EXCEPTION;
              CLOSE C_PLAN_EXCEPTION;
              --
              OPEN C_VALIDA_PLAN_EXCENTO(FONOS_ROW.PLAN, M_PLAN_EXCEPTION);
              FETCH C_VALIDA_PLAN_EXCENTO
                INTO M_VALIDA_PLAN;
              IF C_VALIDA_PLAN_EXCENTO%NOTFOUND THEN
               IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then

                  ORI_FLAG := Paq_Matriz_Validaciones.Busca_Origen_Cob(FONOS_ROW.TIP_SER,
                                                                       FONOS_ROW.TIP_COB,
                                                                       FONOS_ROW.COBERTURA,
                                                                       vUsuario,
                                                                       FONOS_ROW.RAMO,
                                                                       FONOS_ROW.COMPANIA);
                  IF ORI_FLAG IS NOT NULL THEN
                    ERROR := '1';
                  END IF;

                  IF ERROR IS NOT NULL THEN
                    vESTUDIO_REPETICION := BUSCA_COB_ESTUDIO_REPETICION(FONOS_ROW.ASEGURADO,
                                                                        FONOS_ROW.DEPENDIENTE,
                                                                        FONOS_ROW.COMPANIA,
                                                                        FONOS_ROW.RAMO,
                                                                        FONOS_ROW.SECUENCIAL,
                                                                        FONOS_ROW.TIP_SER,
                                                                        FONOS_ROW.TIP_COB,
                                                                        FONOS_ROW.COBERTURA,
                                                                        vUsuario);

                    IF NVL(vESTUDIO_REPETICION, 'N') = 'S' THEN
                      ERROR := NULL;
                    END IF;
                  END IF;

                  IF ERROR IS NULL THEN
                    -- Htorres - 29/09/2019
                    -- Monto maximo que se pueda otorgar para esa cobertura por canales
                    vMON_MAX_COB_ORIGEN := BUSCA_ORIGEN_COB_MON_MAX(FONOS_ROW.TIP_SER,
                                                                    FONOS_ROW.TIP_COB,
                                                                    FONOS_ROW.COBERTURA,
                                                                    vUsuario);
                  END IF;
                END IF;
              END IF;
              CLOSE C_VALIDA_PLAN_EXCENTO;
              --
              IF ERROR IS NULL THEN
                /* ----------------------------------------------------------------------*/
                /* --------------------------------------------------------------------- */
                /*  Busca Limite de monto por cobertura de salud                         */
                /* --------------------------------------------------------------------- */

                /* If..End if adicionado para condicionar si la poliza esta exento
                   de restriccion.  Roche Louis/TECHNOCONS. d/f 17-Dic-2009 8:57am
                */
                IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then

                  --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                  LIMITE_LABORATORIO := dbaper.PAQ_RECLAMACION_SI.F_TIP_COB_MON_MAX(FONOS_ROW.COMPANIA,
                                                                                    FONOS_ROW.RAMO,
                                                                                    FONOS_ROW.SECUENCIAL,
                                                                                    FONOS_ROW.PLAN,
                                                                                    FONOS_ROW.TIP_SER,
                                                                                    FONOS_ROW.TIP_COB,
                                                                                    P_MON_EXE,
                                                                                    P_UNI_T_EXE,
                                                                                    P_RAN_EXE,
                                                                                    P_POR_COA,
                                                                                    P_UNI_T_MAX,
                                                                                    V_MON_DED_TIP_COB, -- Variable Provisional
                                                                                    V_MOD_A_DED, -- Variable Provisional
                                                                                    V_UNI_TIE_DED, -- Variable Provisional
                                                                                    V_RAN_U_DED, -- Variable Provisional
                                                                                    V_FOR_M_EXC, -- Variable Provisional
                                                                                    fecha_dia, -- Variable Provisional
                                                                                    var_frecuencia, -- Variable Provisional
                                                                                    FONOS_ROW.tip_rec, -- Variable Provisional
                                                                                    FONOS_ROW.afiliado, -- Variable Provisional
                                                                                    V_CAL_COP_RANG, -- Variable Provisional
                                                                                    V_NO_APL_SER, -- Variable Provisional)
                                                                                    TRUNC(SYSDATE),
                                                                                    v_error_handler);
                  --
                END IF;
                --<84770>
                --
                --P_MON_DED_TIP_COB);
                /* --------------------------------------------------------------------- */
                /* Valida que el Asegurado puede Recibir la Cobertura de Salud.          */
                /* --------------------------------------------------------------------- */
              if FONOS_ROW.TIP_SER      = 8 and v_proveedor_int in (4014,4013,4012,5372,1942)then
                error := Paq_Matriz_Validaciones.CHK_COBERTURA_ASEGURADO_FONO(TRUE,
                                                                              FONOS_ROW.TIP_REC,
                                                                              FONOS_ROW.AFILIADO,
                                                                              DES_TIP_N_MED,
                                                                              VAR_TIP_A_USO,
                                                                              COD_ASE,
                                                                              COD_DEP,
                                                                              FONOS_ROW.COMPANIA,
                                                                              FONOS_ROW.RAMO,
                                                                              FONOS_ROW.SECUENCIAL,
                                                                              FONOS_ROW.PLAN,
                                                                              FONOS_ROW.TIP_SER,
                                                                              FONOS_ROW.TIP_COB,
                                                                              FONOS_ROW.COBERTURA,
                                                                              VAR_TIP_SER2,
                                                                              FECHA_DIA,
                                                                              FONOS_ROW.SEXO,
                                                                              FONOS_ROW.EST_CIV,
                                                                              VAR_CATEGORIA,
                                                                              FONOS_ROW.FEC_NAC,
                                                                              POR_COA,
                                                                              NO_M_COB_ROW.LIMITE,
                                                                              PLA_STC_ROW.FRECUENCIA,
                                                                              PLA_STC_ROW.UNI_TIE_F,
                                                                              PLA_STC_ROW.TIE_ESP,
                                                                              PLA_STC_ROW.UNI_TIE_T,
                                                                              PLA_STC_ROW.MON_MAX, --A--
                                                                              PLA_STC_ROW.UNI_TIE_M,
                                                                              PLA_STC_ROW.SEXO,
                                                                              PLA_STC_ROW.EDA_MIN,
                                                                              PLA_STC_ROW.EDA_MAX,
                                                                              P_DSP_EST_CIV,
                                                                              P_DSP_CATEGORIA,
                                                                              MONTO_CONTRATADO,
                                                                              vUsuario,
                                                                              P_POR_COA,
                                                                              P_MONTO_MAX, --A estaba dos veces--
                                                                              PLA_STC_ROW.EXC_MCA,
                                                                              PLA_STC_ROW.MON_DED,
                                                                              v_categoria_int,
                                                                              v_proveedor_int);

              else
                error := Paq_Matriz_Validaciones.CHK_COBERTURA_ASEGURADO_FONO(TRUE,
                                                                              FONOS_ROW.TIP_REC,
                                                                              FONOS_ROW.AFILIADO,
                                                                              DES_TIP_N_MED,
                                                                              VAR_TIP_A_USO,
                                                                              COD_ASE,
                                                                              COD_DEP,
                                                                              FONOS_ROW.COMPANIA,
                                                                              FONOS_ROW.RAMO,
                                                                              FONOS_ROW.SECUENCIAL,
                                                                              FONOS_ROW.PLAN,
                                                                              FONOS_ROW.TIP_SER,
                                                                              FONOS_ROW.TIP_COB,
                                                                              FONOS_ROW.COBERTURA,
                                                                              VAR_TIP_SER2,
                                                                              FECHA_DIA,
                                                                              FONOS_ROW.SEXO,
                                                                              FONOS_ROW.EST_CIV,
                                                                              VAR_CATEGORIA,
                                                                              FONOS_ROW.FEC_NAC,
                                                                              POR_COA,
                                                                              NO_M_COB_ROW.LIMITE,
                                                                              PLA_STC_ROW.FRECUENCIA,
                                                                              PLA_STC_ROW.UNI_TIE_F,
                                                                              PLA_STC_ROW.TIE_ESP,
                                                                              PLA_STC_ROW.UNI_TIE_T,
                                                                              PLA_STC_ROW.MON_MAX, --A--
                                                                              PLA_STC_ROW.UNI_TIE_M,
                                                                              PLA_STC_ROW.SEXO,
                                                                              PLA_STC_ROW.EDA_MIN,
                                                                              PLA_STC_ROW.EDA_MAX,
                                                                              P_DSP_EST_CIV,
                                                                              P_DSP_CATEGORIA,
                                                                              MONTO_CONTRATADO,
                                                                              vUsuario,
                                                                              P_POR_COA,
                                                                              P_MONTO_MAX, --A estaba dos veces--
                                                                              PLA_STC_ROW.EXC_MCA,
                                                                              PLA_STC_ROW.MON_DED);
              end if;

              DBMS_OUTPUT.PUT_LINE('CHK_COBERTURA_ASEGURADO_FONO INTERNACIONAL:'||error||' Categoria:'||v_categoria_int||' proveedor:'||v_proveedor_int);

                IF ERROR IS NULL THEN
                  /*---------------------------------------------------------- */
                  /* Valida que no se este digitando una Reclamacion           */
                  /* que ya fue reclamada por el mismo.                        */
                  /* --------------------------------------------------------- */
                  SEC_RECLAMACION := Paq_Matriz_Validaciones.Valida_Rec_Fecha_Null(TRUE,
                                                                                   VAR_ESTATUS_CAN,
                                                                                   FONOS_ROW.ANO_REC,
                                                                                   FONOS_ROW.COMPANIA,
                                                                                   FONOS_ROW.RAMO,
                                                                                   FONOS_ROW.SEC_REC,
                                                                                   FONOS_ROW.TIP_REC,
                                                                                   FONOS_ROW.AFILIADO,
                                                                                   VAR_TIP_A_USO,
                                                                                   COD_ASE,
                                                                                   COD_DEP,
                                                                                   FONOS_ROW.TIP_SER,
                                                                                   FONOS_ROW.TIP_COB,
                                                                                   FONOS_ROW.COBERTURA,
                                                                                   FECHA_DIA);
                  IF SEC_RECLAMACION IS NOT NULL THEN
                    ERROR := '1';
                  END IF;
                  --
                  IF ERROR IS NULL THEN
                    /* ---------------------------------------------------------- */
                    /* Valida que no se este digitando una Reclamacion            */
                    /* que ya fue reclamada por otro que participo en la          */
                    /* aplicacion de la Cobertura.                                */
                    /* ---------------------------------------------------------- */
                    error := Paq_Matriz_Validaciones.Valida_Rec_C_Sal_Fec(TRUE,
                                                                          VAR_ESTATUS_CAN,
                                                                          FONOS_ROW.ANO_REC,
                                                                          FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SEC_REC,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VAR_TIP_A_USO,
                                                                          COD_ASE,
                                                                          COD_DEP,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FECHA_DIA);
                    IF ERROR IS NULL THEN
                      /* ---------------------------------------------------------- */
                      /* Valida:                                                    */
                      /* 1-) Tiempo de Espera de la Cobertura                       */
                      /* ---------------------------------------------------------- */
                      error := Paq_Matriz_Validaciones.Validar_Tiempo_Espera(TRUE,
                                                                             FECHA_DIA,
                                                                             --VAR_FEC_INI,
                                                                             FONOS_ROW.FEC_ING,
                                                                             PLA_STC_ROW.TIE_ESP,
                                                                             PLA_STC_ROW.UNI_TIE_T);

                      IF ERROR IS NULL OR ERROR = '0' -- Caso # 14282
                       THEN
                        /* ---------------------------------------------------------- */
                        /* Valida:                                                    */
                        /* 1-) Cobertura No Exceda la Frecuencia de Uso para su       */
                        /*     Tipo de Cobertura.                                     */
                        /* ---------------------------------------------------------- */
                        /* ***** SOLO Aplica para Tipo_Coberturas:LABORATORIOS ****** */
                        /* ***** en Servicios:AMBULATORIO                      ****** */
                        /* ---------------------------------------------------------- */
                       IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then
                                                                          
                          error := Paq_Matriz_Validaciones.Validar_Frec_Tip_Cob(TRUE,
                                                                                VAR_ESTATUS_CAN,
                                                                                VAR_TIP_A_USO,
                                                                                COD_ASE,
                                                                                COD_DEP,
                                                                                FONOS_ROW.PLAN,
                                                                                FONOS_ROW.TIP_SER,
                                                                                FONOS_ROW.TIP_COB,
                                                                                FONOS_ROW.COBERTURA,
                                                                                FECHA_DIA,
                                                                                VAR_FEC_INI,
                                                                                FONOS_ROW.COMPANIA,
                                                                                FONOS_ROW.RAMO,
                                                                                FONOS_ROW.SECUENCIAL,
                                                                                DSP_COB_LAB,
                                                                                DSP_FREC_TIP_COB);
                          --
                        END IF;
                        --
                        IF ERROR IS NULL THEN
                          /* ---------------------------------------------------------- */
                          /* Valida que en las Reclamaciones:                           */
                          /* 1-) Cobertura No Exceda la Frecuencia de Uso               */
                          /* 2-) Cobertura No Exceda los Montos Maximo.                 */
                          /* ---------------------------------------------------------- */
                         IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then
                                                                          
                            --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                            error := dbaper.PAQ_RECLAMACION_SI.F_VALIDAR_FREC_COBERTURA(TRUE,
                                                                                        VAR_ESTATUS_CAN,
                                                                                        VAR_TIP_A_USO,
                                                                                        COD_ASE,
                                                                                        COD_DEP,
                                                                                        FONOS_ROW.TIP_SER,
                                                                                        FONOS_ROW.TIP_COB,
                                                                                        FONOS_ROW.compania,
                                                                                        FONOS_ROW.ramo,
                                                                                        FONOS_ROW.secuencial,
                                                                                        FONOS_ROW.COBERTURA,
                                                                                        FECHA_DIA,
                                                                                        VAR_FEC_INI,
                                                                                        FONOS_ROW.FEC_ING,
                                                                                        PLA_STC_ROW.FRECUENCIA,
                                                                                        PLA_STC_ROW.UNI_TIE_F,
                                                                                        PLA_STC_ROW.TIE_ESP,
                                                                                        PLA_STC_ROW.UNI_TIE_T,
                                                                                        PLA_STC_ROW.MON_MAX,
                                                                                        PLA_STC_ROW.UNI_TIE_M,
                                                                                        DSP_FREC_ACUM,
                                                                                        DSP_MON_PAG_ACUM,
                                                                                        VAR_PLAN,
                                                                                        TRUNC(SYSDATE),
                                                                                        v_error_handler);
                            --
                          END IF;
                          --</84770>
                          --
                          IF ERROR IS NULL THEN
                            /* --------------------------------------------------- */
                            /* Determina el limite de frecuencia paralelo          */
                            /* por plan por tipo de cobertura                      */
                            /* --------------------------------------------------- */
                           IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then
                              --
                              ERROR := Paq_Matriz_Validaciones.validar_frec_tip_cob_fono(p_field_level     => TRUE,
                                                                                         p_var_estatus_can => VAR_ESTATUS_CAN, -- Cancelada en la Rec
                                                                                         p_tip_a_uso       => VAR_TIP_A_USO,
                                                                                         p_ase_uso         => COD_ASE,
                                                                                         p_dep_uso         => COD_DEP,
                                                                                         p_plan            => FONOS_ROW.PLAN,
                                                                                         p_servicio        => FONOS_ROW.TIP_SER,
                                                                                         p_tip_cob         => FONOS_ROW.TIP_COB,
                                                                                         p_cobertura       => FONOS_ROW.COBERTURA,
                                                                                         p_fec_ser         => FECHA_DIA,
                                                                                         p_fec_ini_pol     => VAR_FEC_INI,
                                                                                         p_fec_ing         => FONOS_ROW.FEC_ING,
                                                                                         p_frecuencia      => var_frecuencia,
                                                                                         p_uni_tie_f       => var_uni_tie_f,
                                                                                         p_tie_esp         => PLA_STC_ROW.TIE_ESP,
                                                                                         p_uni_tie_t       => PLA_STC_ROW.UNI_TIE_T,
                                                                                         p_mon_max         => PLA_STC_ROW.MON_MAX,
                                                                                         p_uni_tie_m       => PLA_STC_ROW.UNI_TIE_M,
                                                                                         p_dsp_frec_acum   => var_dsp_frec_acum);

                              --
                            END IF;
                            --
                            IF ERROR IS NULL THEN
                              /* ---------------------------------------------------  */
                              /* Determina si el afiliado digita el Monto a Reclamar  */
                              /* para igualar el limite al monto digitado             */
                              /* ---------------------------------------------------  */
                              --VIA FONOSALUD EL AFILIADO NO DIGITA NINGUN MONTO A RECLAMAR--
                              --VIA POS EL AFILIADO DIGITA EL MONTO A RECLAMAR--
                              IF NVL(to_number(p_instr2), 0) > 0 THEN
                                IF NVL(to_number(p_instr2), 0) <
                                   NO_M_COB_ROW.LIMITE THEN
                                  FONOS_ROW.MON_REC_AFI := to_number(p_instr2);
                                ELSE
                                  FONOS_ROW.MON_REC_AFI := NO_M_COB_ROW.LIMITE;
                                END IF;
                              END IF;
                              IF FONOS_ROW.MON_REC_AFI IS NOT NULL AND
                                 FONOS_ROW.MON_REC_AFI <> 0 THEN
                                NO_M_COB_ROW.LIMITE := FONOS_ROW.MON_REC_AFI;
                              END IF;
                              /*-------------------------------------------------------------- */
                              /* Buscar monto acumulados de reclamaciones en periodo de tiempo,*/
                              /* si tiene monto excento por tipo de cobertura                   */
                              /*-------------------------------------------------------------- */
                              P_MON_ACUM := 0;
                              IF P_MON_EXE IS NOT NULL AND P_MON_EXE <> 0 THEN
                                /* -----------------------------------------------------------------------  */
                                /* Obtiene la Fecha Inicial segun la Unidad de Tiempo                       */
                                /* de monto excento para determinar si ha excedido el Uso de la Cobertura.  */
                                /* -----------------------------------------------------------------------  */
                                T_FEC_INI := Paq_Matriz_Validaciones.Determina_Fecha_Rango(FECHA_DIA,
                                                                                           VAR_FEC_INI,
                                                                                           NULL,
                                                                                           NULL,
                                                                                           NULL,
                                                                                           P_RAN_U_EXC,
                                                                                           P_MON_EXE,
                                                                                           NVL(P_UNI_T_EXE,
                                                                                               365));
                                /* ----------------------------------------------------------------------  */
                                /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto excento   */
                                /* para determinar si ha excedido el Uso excento de la Cobertura.          */
                                /* ----------------------------------------------------------------------  */
                                T_FEC_FIN := Paq_Matriz_Validaciones.Determina_Fecha_Rango_Fin(FECHA_DIA,
                                                                                               VAR_FEC_INI,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               P_MON_EXE,
                                                                                               NVL(P_UNI_T_EXE,
                                                                                                   365),
                                                                                               P_RAN_U_EXC);
                                /* Si la Fecha Fin es null, entonces sera igual */
                                /* a la Fecha de Servicio.      */
                                IF T_FEC_FIN IS NULL THEN
                                  T_FEC_FIN := FECHA_DIA;
                                END IF;

                                --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                                P_MON_ACUM := dbaper.PAQ_RECLAMACION_SI.F_BUSCA_REC_ACU(VAR_TIP_A_USO,
                                                                                        COD_ASE,
                                                                                        COD_DEP,
                                                                                        FECHA_DIA,
                                                                                        FONOS_ROW.COMPANIA,
                                                                                        FONOS_ROW.RAMO,
                                                                                        FONOS_ROW.PLAN,
                                                                                        FONOS_ROW.TIP_SER,
                                                                                        FONOS_ROW.TIP_COB,
                                                                                        VAR_ESTATUS_CAN,
                                                                                        T_FEC_INI,
                                                                                        T_FEC_FIN,
                                                                                        VAR_TIPO, -- Variable Provisional
                                                                                        VAR_SECUENCIAL, -- Variable Provisional
                                                                                        TRUNC(SYSDATE));

                              DBMS_OUTPUT.PUT_LINE('PAQ_RECLAMACION_SI.F_BUSCA_REC_ACU:'||error||' monto acumulado:'|| P_MON_ACUM);
                                --</84770>
                              END IF;
                              --Se iguala variable al Monto a Pagar para enviar al proceso que obtiene deducible Salud Internacional
                              --<84770>

                              var_deducible := NVL(var_deducible, 0); --<84770.4> JTAVERAS

                              --<84770> DMENENES 29JUN2015
                              --Proceso para buscar datos de CarryOver Salud Internacional

                              /* v_error_handler := VALID_RANGO_CARRYOVER@PER_vid.WORLD(FONOS_ROW.plan,
                              fecha_dia,
                              V_CARRYOVER,
                              V_FEC_I_CAR,
                              V_FEC_F_CAR,
                              V_MENSAJE);*/
                              --</84770>

                              --<84770> DMENENES 29JUN2015
                              --Proceso para buscar codigo de asegurado equivalente en SaludCore para enviar al proceso F_OBT_DATOS_DED
                              vafiliado_SAL := null;/*dbaper.paq_sync_reclamacion.f_busca_asegurado(COD_ASE,
                                                                                             nvl(cod_dep,
                                                                                                 0), --<84770.4> JTAVERAS
                                                                                             fonos_row.compania,
                                                                                             fonos_row.ramo,
                                                                                             fonos_row.secuencial,
                                                                                             VAR_TIP_A_USO);*/
                              --</84770>
                              -- Migracion Salud internacional
                              IF (vafiliado_sal IS NULL OR
                                 vafiliado_sal = 0) THEN
                                vafiliado_sal := DBAPER.PAQ_RECLAMACION_SI.F_ASE_DEP_CODIGO(COD_ASE,
                                                                                            COD_DEP,
                                                                                            FONOS_ROW.COMPANIA,
                                                                                            FONOS_ROW.RAMO,
                                                                                            FONOS_ROW.SECUENCIAL);
                              END IF;
                              --<84770> DMENENES 29JUN2015
                              --Proceso que busca el deducible del plan elegido por el asegurado en SaludCore

                              v_error_handler := dbaper.paq_reclamacion_si.F_OBT_DATOS_DED(1,
                                                                                           V_MON_MAX,
                                                                                           V_DIAS_TIP_COB,
                                                                                           V_MON_DISP_TC,
                                                                                           NO_M_COB_ROW.LIMITE, --               ,
                                                                                           var_frecuencia,
                                                                                           fonos_row.TIP_COB,
                                                                                           fonos_row.SECUENCIAL,
                                                                                           fonos_row.ramo,
                                                                                           fonos_row.compania,
                                                                                           fonos_row.ANO_rec,
                                                                                           'A',
                                                                                           'A',
                                                                                           V_VAR_IND_DED,
                                                                                           fonos_row.secuencial,
                                                                                           fonos_row.plan,
                                                                                           vafiliado_sal,
                                                                                           var_tip_a_uso,
                                                                                           fecha_dia,
                                                                                           'L',
                                                                                           'P',
                                                                                           V_APL_DED_RIE,
                                                                                           V_IND_DED_RIE,
                                                                                           VAR_FEC_INI, --t_fec_ini                            ,
                                                                                           DSP_FEC_ING,
                                                                                           fonos_row.tip_ser,
                                                                                           fonos_row.COBERTURA,
                                                                                           'S',
                                                                                           V_FEC_I_CAR,
                                                                                           V_FEC_F_CAR,
                                                                                           V_IND_DED_CAS,
                                                                                           V_NUMERO_CASO,
                                                                                           VAR_DEDUCIBLE, --<84770.4> JTAVERAS :REC_C_SAL13.VAR_DEDUCIBLE ,
                                                                                           fonos_row.mon_rec, --<84770.4> JTAVERAS V_MON_PAG_DG              ,
                                                                                           V_ACUM_REC_G,
                                                                                           fonos_row.mon_rec, --<84770.4> JTAVERAS V_MON_PAG_DG                           ,
                                                                                           fonos_row.mon_rec, --<84770.4> JTAVERAS V_MON_PAG_BK                         ,
                                                                                           v_RESERVA,
                                                                                           V_valida_limite,
                                                                                           0); --<84770.4> JTAVERAS :rec_c_sal13.sum_mon_pag

                              --<84770.4> JTAVERAS
                              DBMS_OUTPUT.PUT_LINE('paq_reclamacion_si.F_OBT_DATOS_DED:'||v_error_handler);
                              V_DEDUCIBLE_MIREX := 0;
                              V_DEDUCIBLE_MIREX := VAR_DEDUCIBLE;

							  /*
							     -- PROBLEM 144879  << DMENESES 22/09/2022 >>
								 SE AGREGGO ESTA CONDICION IF PORQUE ESTABA COLOCANDO EN CERO EL COASEGURO DESPUES
							     QUE LO BUSCA DE LA CONFIGURACION NORMAL DE LA COBERTURA
							  */
							  IF POR_COA IS NULL AND NO_M_COB_ROW.LIMITE IS NULL AND VAR_FRECUENCIA IS NULL THEN
                              --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                              V_ERROR_HANDLER := PAQ_RECLAMACION_SI.F_BUSCAR_COASEG_FREC_MONTO(FONOS_ROW.TIP_REC,
                                                                                               FONOS_ROW.AFILIADO,
                                                                                               VAR_TIP_A_USO,
                                                                                               COD_ASE,
                                                                                               COD_DEP,
                                                                                               FONOS_ROW.COMPANIA,
                                                                                               FONOS_ROW.RAMO,
                                                                                               FONOS_ROW.SECUENCIAL,
                                                                                               FONOS_ROW.PLAN,
                                                                                               FONOS_ROW.TIP_SER,
                                                                                               FONOS_ROW.TIP_COB,
                                                                                               FONOS_ROW.COBERTURA,
                                                                                               FECHA_DIA,
                                                                                               POR_COA,
                                                                                               NO_M_COB_ROW.LIMITE,
                                                                                               VAR_FRECUENCIA,
                                                                                               DSP_UNI_TIE_F,
                                                                                               VAR_UNI_T_EXE,
                                                                                               V_MON_MAX,
                                                                                               DSP_TIE_ESP,
                                                                                               DSP_UNI_T_ESP,
                                                                                               'GEN',
                                                                                               FECHA_DIA);

                            DBMS_OUTPUT.PUT_LINE('paq_reclamacion_si.F_BUSCAR_COASEG_FREC_MONTO:'||v_error_handler);
                              --</84770>
							  END IF;

                              /* ------------------------------------------------------------- */
                              /* Procedure que llama los program unit que realizan el          */
                              /* Calculo de la Reserva.               */
                              /* ------------------------------------------------------------- */
                              /*
                              Calcular_Reserva(NO_M_COB_ROW.LIMITE,
                                               NO_M_COB_ROW.POR_DES,
                                               POR_COA,
                                               FONOS_ROW.MON_PAG,
                                               FONOS_ROW.MON_DED,
                                               P_MON_EXE,
                                               P_MON_ACUM);
                               */

                              VAR_FRECUENCIA := 1;

                              --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                              dbaper.PAQ_RECLAMACION_SI.P_CALCULAR_RESERVA(NO_M_COB_ROW.LIMITE *
                                                                           var_frecuencia,
                                                                           NO_M_COB_ROW.LIMITE,
                                                                           var_frecuencia,
                                                                           POR_COA,
                                                                           NO_M_COB_ROW.POR_DES,
                                                                           v_reserva,
                                                                           FONOS_ROW.MON_PAG,
                                                                           v_mon_max,
                                                                           p_mon_acum,
                                                                           -- :OBJETAR_RADICACION.VAR_MON_EXE *Este parametro no se encuentra en el procedimiento del paquete.
                                                                           VAR_MON_E_COA, -- Variable Provisional
                                                                           VAR_FOR_E_COA, -- Variable Provisional
                                                                           var_deducible, -- Variable Provisional
                                                                           VAR_MOD_A_DED, -- Variable Provisional
                                                                           VAR_MON_R_DED, -- Variable Provisional
                                                                           vAR_MON_COA, -- Variable Provisional
                                                                           fecha_dia,
                                                                           V_error_handler);

                              ----- AGREGADO PARA BUSCAR EL GRUPO Y ENVIARLO A LA FUNCION.
                              V_GRUPO := 'GEN';
                              IF TO_NUMBER(V_MIREX) =
                                 TO_NUMBER(fonos_row.PLAN) THEN
                                V_GRUPO := DBAPER.VAL_GRUPO_X_TIP_COB_GRUPO(fonos_row.PLAN,
                                                                            fonos_row.TIP_SER,
                                                                            fonos_row.TIP_COB);
                              END IF;
                              -----
                              IF VAR_TIP_A_USO = 'ASEGURADO' THEN
                                OPEN Cur_Ase;
                                FETCH Cur_Ase
                                  INTO VDSP_FEC_ING;
                                CLOSE Cur_Ase;
                              ELSE
                                OPEN Cur_Dep;
                                FETCH Cur_Dep
                                  INTO VDSP_FEC_ING;
                                CLOSE Cur_Dep;
                              END IF;
                              --
                              V_EDAD_AFILIADO := NULL;
                              V_EDAD_AFILIADO := TRUNC(((MONTHS_BETWEEN(TRUNC(SYSDATE),
                                                                        FONOS_ROW.FEC_NAC)) / 12),
                                                       0);
                              V_ANO_SERVICIO  := to_char(sysdate, 'yyyy');
                              VMESSAGE        := NULL;

                              ----------- ESTE BLOQUE ES PARA CONTROLAR EL TEMA DE CUANDO SE LLEGA AL LIMITE EN MEDIO DE UNA RECLAMACION.
                              SELECT SUM(MON_PAG)
                                INTO V_MONTO_ACUMULADO_COBER
                                FROM INFOX_SESSION
                               WHERE NUMSESSION = p_numsession; -- para la segunda etapa

                              DBAPER.PAQ_RECLAMACION_SI.P_VAL_MON_MAX_GRU(V_ANO_SERVICIO, --fonos_row.ano_rec,
                                                                          fonos_row.COMPANIA,
                                                                          fonos_row.RAMO,
                                                                          fonos_row.secuencial,
                                                                          fonos_row.PLAN,
                                                                          vafiliado_SAL, --:RECLAMAC12.ASE_USO
                                                                          var_TIP_A_USO,
                                                                          V_EDAD_AFILIADO, --<8477.4> JTAVERAS 09JUL2015 null
                                                                          fecha_dia,
                                                                          VAR_FEC_INI,
                                                                          VDSP_FEC_ING,
                                                                          NULL, --fonos_row.secuencial
                                                                          FONOS_ROW.TIP_COB,
                                                                          fonos_row.MON_PAG, --V_MON_REC_DG
                                                                          fonos_row.MON_PAG, --VMON_PAG_TC
                                                                          V_GRUPO,
                                                                          NVL(VMON_FEE_TC,
                                                                              0),
                                                                          VMON_FEE,
                                                                          VMESSAGE,
                                                                          fonos_row.MON_PAG,
                                                                          'N', --VFLAG_DEL_COB
                                                                          fecha_dia);

                              V_MONPAG_DEVUELVE_FUNCION := fonos_row.MON_PAG;
                              --</84770>
                              /* --Htorres
                              Paq_Matriz_Validaciones.CALCULAR_RESERVA(
                                    NO_M_COB_ROW.LIMITE, --FONOS_ROW.MON_REC_AFI,
                                    NO_M_COB_ROW.LIMITE,
                                    PLA_STC_ROW.FRECUENCIA,
                                    POR_COA,
                                    NO_M_COB_ROW.POR_DES,
                                    P_RESERVA,
                                    fonos_row.mon_pag,
                                    PLA_STC_ROW.MON_MAX,
                                    P_MON_ACUM,
                                    FONOS_ROW.MON_DED --PLA_STC_ROW.MON_DED
                                    );   */
                              --
                              MONTO_LABORATORIO := 0;
                              --
                              IF LIMITE_LABORATORIO IS NOT NULL AND
                                 LIMITE_LABORATORIO <> 0 THEN
                                -- Si tiene limite monto maximo por tipo de cobertura, entonces procede a buscar monto acumulado  --
                                /* ---------------------------------------------------------- */
                                /* Valida:                                                    */
                                /* 1-) Cobertura No Exceda el Monto a Pagar para Tipo de      */
                                /*     Cobertura de Laboratorio y Rayos X en Ambulatorios.    */
                                /* ---------------------------------------------------------- */
                                /* ----------------------------------------------------------------------- */
                                /* Obtiene la Fecha Inicial segun la Unidad de Tiempo                      */
                                /* de monto maximo para determinar si ha excedido el Uso de la Cobertura.  */
                                /* ----------------------------------------------------------------------- */
                                T_FEC_INI := Paq_Matriz_Validaciones.Determina_Fecha_Rango(FECHA_DIA,
                                                                                           VAR_FEC_INI,
                                                                                           NULL,
                                                                                           NULL,
                                                                                           NULL,
                                                                                           P_RAN_U_EXC,
                                                                                           LIMITE_LABORATORIO,
                                                                                           NVL(P_UNI_T_MAX,
                                                                                               365));
                                /* ---------------------------------------------------------------------- */
                                /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto maximo       */
                                /* para determinar si ha excedido el Uso maximo de la Cobertura.          */
                                /* ---------------------------------------------------------------------- */
                                T_FEC_FIN := Paq_Matriz_Validaciones.Determina_Fecha_Rango_Fin(FECHA_DIA,
                                                                                               VAR_FEC_INI,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               LIMITE_LABORATORIO,
                                                                                               NVL(P_UNI_T_MAX,
                                                                                                   365),
                                                                                               P_RAN_U_EXC);
                                /* Si la Fecha Fin es null, entonces sera igual */
                                /* a la Fecha de Servicio.     */
                                IF T_FEC_FIN IS NULL THEN
                                  T_FEC_FIN := FECHA_DIA;
                                END IF;
                                --
                                MONTO_LABORATORIO := Paq_Matriz_Validaciones.Validar_Lab_Rayos(VAR_TIP_A_USO,
                                                                                               COD_ASE,
                                                                                               COD_DEP,
                                                                                               FECHA_DIA,
                                                                                               FONOS_ROW.COMPANIA,
                                                                                               FONOS_ROW.RAMO,
                                                                                               FONOS_ROW.SECUENCIAL,
                                                                                               FONOS_ROW.PLAN,
                                                                                               FONOS_ROW.TIP_SER,
                                                                                               FONOS_ROW.TIP_COB,
                                                                                               FONOS_ROW.COBERTURA,
                                                                                               VAR_ESTATUS_CAN,
                                                                                               T_FEC_INI,
                                                                                               T_FEC_FIN);
                                --
                                MONTO_LABORATORIO := MONTO_LABORATORIO + FONOS_ROW.MON_PAG;
                                IF MONTO_LABORATORIO > LIMITE_LABORATORIO THEN
                                  ERROR := '1';
                                END IF;
                                --
                              END IF; /*END LIMITE_LABORATORIO IS NOT NULL*/

                              -- Htorres - 29/09/2019
                              -- Monto maximo que se pueda otorgar para esa cobertura por canales
                              IF NVL(vMON_MAX_COB_ORIGEN, 0) > 0 AND
                                 (FONOS_ROW.MON_PAG > vMON_MAX_COB_ORIGEN) THEN
                                ERROR := '1';
                              END IF;
                              --
                              IF ERROR IS NULL THEN
                                /***************************************************/
                                /*    Validar que el afiliado pueda reclamar en el plan del asegurado */
                                /***************************************************/
                                ERROR1 := Paq_Matriz_Validaciones.Validar_Plan_Afiliado(fonos_row.PLAN,
                                                                                        fonos_row.tip_ser,
                                                                                        fonos_row.tip_rec,
                                                                                        FONOS_ROW.AFILIADO);

                                IF ERROR1 THEN
                                  /***************************************************/
                                  /*    Validar coberturas mutuamente excluyente     */
                                  /***************************************************/
                                  ERROR := Paq_Matriz_Validaciones.Valida_Cob_Excluyente(TRUE,
                                                                                         VAR_ESTATUS_CAN,
                                                                                         VAR_TIP_A_USO,
                                                                                         COD_ASE,
                                                                                         COD_DEP,
                                                                                         FONOS_ROW.TIP_SER,
                                                                                         FONOS_ROW.TIP_COB,
                                                                                         FONOS_ROW.COBERTURA,
                                                                                         FECHA_DIA,
                                                                                         VAR_FEC_INI,
                                                                                         FONOS_ROW.FEC_ING,
                                                                                         PLA_STC_ROW.FRECUENCIA,
                                                                                         PLA_STC_ROW.UNI_TIE_F,
                                                                                         FONOS_ROW.PLAN);
                                  IF ERROR IS NULL THEN
                                    /***************************************************/
                                    /*    Validar Beneficio Maximo por Familia         */
                                    /***************************************************/
                                    ERROR1 := Paq_Matriz_Validaciones.Validar_Beneficio_Max(FONOS_ROW.COMPANIA,
                                                                                            FONOS_ROW.RAMO,
                                                                                            FONOS_ROW.SECUENCIAL,
                                                                                            FONOS_ROW.PLAN,
                                                                                            COD_ASE,
                                                                                            FECHA_DIA,
                                                                                            VAR_FEC_INI,
                                                                                            FONOS_ROW.FEC_ING,
                                                                                            FONOS_ROW.MON_PAG,
                                                                                            NULL);
                                    IF NOT (ERROR1) THEN
                                      /* --------------------------------------------- */
                                      /* Valida que el Monto Maximo digitado no exceda */
                                      /* el especificado en la Cobertura, solo para farmacias. */
                                      /* --------------------------------------------- */
                                      IF (FONOS_ROW.MON_REC_AFI IS NOT NULL AND
                                         FONOS_ROW.MON_REC_AFI <> 0) AND
                                         (PLA_STC_ROW.MON_MAX IS NOT NULL AND
                                         PLA_STC_ROW.MON_MAX <> 0) THEN
                                        IF (NVL(DSP_MON_PAG_ACUM, 0) +
                                           FONOS_ROW.MON_PAG) <
                                           PLA_STC_ROW.MON_MAX THEN
                                          VAR_CODE := 0;
                                        ELSE
                                          FONOS_ROW.MON_REC_AFI := PLA_STC_ROW.MON_MAX - DSP_MON_PAG_ACUM;
                                          VAR_CODE              := 2;
                                        END IF;
                                      ELSE
                                        VAR_CODE := 0;
                                      END IF;
                                    ELSE
                                      VAR_CODE := 2;
                                    END IF;
                                  ELSE
                                    var_code := 2;
                                  END IF;
                                ELSE
                                  var_code := 2;
                                END IF;
                              ELSE
                                var_code := 2;
                              END IF;
                            ELSE
                              -- del plan tipo de cobertura paralelo
                              var_code := 2;
                            END IF;
                          ELSE
                            var_code := 2;
                          END IF;
                        ELSE
                          var_code := 2;
                        END IF;
                      ELSE
                        var_code := 2;
                      END IF;
                    ELSE
                      var_code := 2;
                    END IF;
                  ELSE
                    var_code := 2;
                  END IF;
                ELSE
                  var_code := 2;
                END IF;
              ELSE
                var_code := 2;
              END IF;
            ELSE
              var_code := 3;
            END IF;
          ELSE
            var_code := 1;
          END IF;
        END IF;
      ELSE
        var_code := 1;
      END IF;

      IF VAR_CODE = 0 THEN
        -- Para verificar si no hay ningun error
        -- VALIDAR_COBERTURA: Funcion para controlar la cobertura 2836 ------------------------------
        -- * Esta cobertura solo estara disponible en horario de 6:00 pm a 6:00 am
        -- * Las clinicas paquetes no deben reclamar por esta cobertura
        -- * Los medicos categoria A+ (Platinum) estan excepto de estas validaciones
        -- * Las excepciones deben poder ser manejadas por un superusuario
        -- * Para que el medico pueda reclamar el servicio el asegurado debe tener
        --   una reclamacion del mismo servicio (EMERGENCIA) por lo menos de 72 horas de antelacion.
        ---------------------------------------------------------------------------------------------
        /*
              IF FONOS_ROW.COBERTURA = 2836 THEN
                IF SUBSTR(VALIDAR_COBERTURA(vUSUARIO, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, FONOS_ROW.TIP_SER, 2836, SYSDATE, COD_DEP, COD_ASE), 1, 1) != '0' THEN
                   VAR_CODE := 2;
                END IF;
             END IF;
             -- Validar cobertura 2836
        */
        IF FONOS_ROW.TIP_SER <> 3 THEN
          -- SERVICIO DE EMERGENCIA
          -- Suspencion por Suplantacion (Fraude)
          mFRAUDE := 'N';

          -- para verificar si el afiliado tiene una marca de suspencion del servicio de salud
          OPEN C_FRAUDE;
          FETCH C_FRAUDE
            INTO mFRAUDE;
          CLOSE C_FRAUDE;

          IF mFRAUDE = 'S' THEN
            VAR_CODE := 2; -- VAR_CODE := 2;
          END IF;
          -- Fraude
        END IF;

      END IF; -- IF VAR_CODE <> 0 THEN

      --
      --<84770> jdeveaux --> Se busca si tiene poliza local
      --      dbaper.paq_reclamacion_si.p_busca_polizas (fonos_row.compania, cod_ase, cod_dep, fecha_dia, v_ramo, v_sec_pol, 'LOCAL');
      --</84770>

      if (var_code = 0 and nvl(fonos_row.mon_pag, 0) > 0) /* or (v_sec_pol is null)*/
       then
        --<84770> jdeveaux --> Se condiciona a que solo grabe si tiene cobertura o si no tiene poliza local

        fonos_row.mon_pag   := ROUND(fonos_row.mon_pag, 2);
        no_m_cob_row.limite := ROUND(no_m_cob_row.limite, 2);
        fonos_row.por_coa   := ROUND(por_coa, 2);
        fonos_row.mon_ded   := ROUND(fonos_row.MON_DED, 2);
        --
        UPDATE INFOX_SESSION
           SET CODE         = VAR_CODE,
               TIP_SER      = FONOS_ROW.TIP_SER,
               TIP_COB      = FONOS_ROW.TIP_COB,
               R_TIP_COB    = FONOS_ROW.TIP_COB,
               MON_REC      = NO_M_COB_ROW.LIMITE,
               MON_PAG      = FONOS_ROW.MON_PAG,
               POR_COA      = FONOS_ROW.POR_COA,
               DES_COB      = COB_SAL_ROW.DESCRIPCION,
               MON_REC_AFI  = FONOS_ROW.MON_REC_AFI,
               COBERTURA    = FONOS_ROW.COBERTURA,
               MON_DED      = var_deducible,
               COBERTURASTR = P_INSTR1
         WHERE numsession = p_numsession;
        CLOSE A;

        -- Victor Acevedo / TECHNOCONS.
        P_OUTSTR1 := ltrim(to_char(fonos_row.mon_pag, '999999990.00'));
        P_OUTSTR2 := ltrim(to_char(nvl(fonos_row.mon_ded, 0),
                                   '999999990.00'));
        p_outnum1 := VAR_CODE;

      else
        --<84770> jdeveaux --> Si tiene poliza local y no tiene cobertura internacional, se procesa por el plan local
        open c_numpla(COD_ASE, COD_DEP);
        fetch c_numpla
          into v_num_pla;
        close c_numpla;

        P_VALIDATEASEGURADO_LOC('VALIDATEASEGURADO',
                                p_numsession,
                                v_num_pla,
                                p_instr2,
                                p_innum1,
                                p_innum2,
                                p_outstr1,
                                p_outstr2,
                                p_outnum1,
                                p_outnum2);

        if p_outnum1 = 0 then --local
          P_VALIDATECOBERTURA_LOC(p_name,
                                  p_numsession,
                                  p_instr1,
                                  p_instr2,
                                  p_innum1,
                                  p_innum2,
                                  p_outstr1,
                                  p_outstr2,
                                  p_outnum1,
                                  p_outnum2);
        end if;

      end if;
      --  end if; --MIREX
    END;

  END;

  --
  -- --<84770> jdeveaux --> PROCESO PARA VALIDAR COBERTURA PARA PLANES LOCALES, SI POR EL INTERNACIONAL NO TENIA COBERTURA
  -- procedure inserta una cobertura en la reclamacion abierta por open reclamacion --
  -- 0->ok 1-> error --

  PROCEDURE P_VALIDATECOBERTURA_LOC(p_name       IN VARCHAR2,
                                    p_numsession IN NUMBER,
                                    p_instr1     IN VARCHAR2,
                                    p_instr2     IN VARCHAR2,
                                    p_innum1     IN NUMBER,
                                    p_innum2     IN NUMBER,
                                    p_outstr1    OUT VARCHAR2,
                                    p_outstr2    OUT VARCHAR2,
                                    p_outnum1    OUT NUMBER,
                                    p_outnum2    OUT NUMBER) IS
  BEGIN
    /* @% Verificar Disponibilidad de Cobertura */
    /* Descripcion : Valida que el Afiliado  pueda ofrecer la cobertura y que el asegurado*/
    /*               pueda recibir la cobertura. */
    DECLARE
      DUMMY            VARCHAR2(1);
      ERROR            CHAR(1);
      ERROR1           BOOLEAN; /*  Se utiliza igual que ERROR, pero es enviada en algunos casos que la funcion devuelve boolean */
      CAT_PLAN_ODON      BOOLEAN;
      VAR_CODE         NUMBER(2) := 1;
      FONOS_ROW        INFOX_SESSION%ROWTYPE;
      SER_SAL_ROW      SER_SAL%ROWTYPE;
      TIP_C_SAL_ROW    TIP_C_SAL%ROWTYPE;
      COB_SAL_ROW      COB_SAL%ROWTYPE;
      NO_M_COB_ROW     NO_M_COB%ROWTYPE;
      DES_TIP_N_MED    TIPO_NO_MEDICO.DESCRIPCION%TYPE;
      COD_ASE          NUMBER(11);
      COD_DEP          NUMBER(3);
      VAR_TIP_SER2     SER_SAL.CODIGO%TYPE;
      FECHA_DIA        DATE;
      POR_COA          POL_P_SER.POR_COA%TYPE;
      PLA_STC_ROW      PLA_STC%ROWTYPE;
      VAR_ESTATUS_CAN  RECLAMACION.ESTATUS%TYPE := 183;
      VAR_TIP_A_USO    RECLAMACION.TIP_A_USO%TYPE;
      VAR_FEC_INI      POLIZA.FEC_INI%TYPE;
      VAR_FEC_FIN      POLIZA.FEC_FIN%TYPE;
      T_FEC_INI        POLIZA.FEC_INI%TYPE;
      T_FEC_FIN        POLIZA.FEC_FIN%TYPE;
      DSP_COB_LAB      NUMBER;
      DSP_FREC_TIP_COB NUMBER;
      DSP_FREC_ACUM    NUMBER;
      DSP_MON_PAG_ACUM NUMBER;
      SEC_RECLAMACION  RECLAMACION.SECUENCIAL%TYPE;
      MONTO_CONTRATADO VARCHAR(1);
      /* Parametro para saber si la cobertura esta contratada con  */
      /* el reclamante o con la poliza (ej. habitacion y medicina) */
      MONTO_LABORATORIO  NUMBER(11, 2);
      VAR_CATEGORIA      VARCHAR2(40);
      P_DSP_CATEGORIA    PLA_STC.CATEGORIA%TYPE;
      P_DSP_EST_CIV      PLA_STC.EST_CIV%TYPE;
      LIMITE_LABORATORIO LIM_C_REC.MON_MAX%TYPE;
      P_MON_EXE          LIM_C_REC.MON_E_COA%TYPE;
      P_UNI_T_EXE        LIM_C_REC.UNI_TIE_E%TYPE;
      P_UNI_T_MAX        LIM_C_REC.UNI_TIE_M%TYPE;
      P_RAN_EXE          LIM_C_REC.RAN_U_EXC%TYPE;
      P_POR_COA          LIM_C_REC.POR_COA%TYPE;
      P_MON_ACUM         NUMBER(14, 2);
      ORI_FLAG           VARCHAR2(1);
      V_INSER            NUMBER(2);
      V_INTIP            NUMBER(3);
      V_INCOB            VARCHAR2(10);
      P_MONTO_MAX        NUMBER(11, 2);
      var_frecuencia     PLA_STC_ROW.FRECUENCIA%type;
      var_uni_tie_f      PLA_STC_ROW.UNI_TIE_F%type;
      var_dsp_frec_acum  DSP_FREC_ACUM%type;
      V_MSG              VARCHAR2(100);
      V_RED_PLAT         NUMBER(3);

      -- Technocons
      mFRAUDE VARCHAR(1);

      vMON_MAX_COB_ORIGEN NUMBER(11, 2);

      v_prov_capitado NUMBER(1) := 0;
      v_prov_basico   NUMBER;
      v_prov_existe   NUMBER;
      v_nuevo         VARCHAR2(1);

      M_PLAN_EXCEPTION VARCHAR2(4000);

      M_VALIDA_PLAN VARCHAR2(4000);
      --
      P_RAN_U_EXC LIM_C_REC.RAN_U_EXC%TYPE;
      P_RAN_U_MAX LIM_C_REC.RAN_U_EXC%TYPE;

      --<jdeveaux 18may2016>
      --Variables para capturar los datos de la poliza original de plan voluntario cambia a la poliza del plan basico
      V_PLAN_ORI     NUMBER(3);
      V_COMPANIA_ORI NUMBER(2);
      V_RAMO_ORI     NUMBER(2);
      V_SEC_ORI      NUMBER(7);
      --</jdeveaux>
      vESTUDIO_REPETICION VARCHAR2(1) := 'N';

      CURSOR C_PLAN_EXCEPTION IS
        SELECT VALPARAM
          FROM TPARAGEN D
         WHERE NOMPARAM IN ('LIB_PLAN_FONO')
           AND COMPANIA = FONOS_ROW.COMPANIA;

      CURSOR C_VALIDA_PLAN_EXCENTO(MPLAN VARCHAR2, M_LISTA_PLAN VARCHAR2) IS
        SELECT COLUMN_VALUE
          FROM TABLE(SPLIT(M_LISTA_PLAN))
         WHERE COLUMN_VALUE = MPLAN;

      CURSOR A IS
        SELECT TIP_REC,
               AFILIADO,
               TIP_COB,
               COBERTURA,
               COMPANIA,
               RAMO,
               SECUENCIAL,
               PLAN,
               ASEGURADO,
               DEPENDIENTE,
               SEXO,
               FEC_ING,
               FEC_NAC,
               ANO_REC,
               SEC_REC,
               CATEGORIA,
               EST_CIV,
               MON_REC_AFI,
               CAT_N_MED,
               TIP_SER
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION
           FOR UPDATE;

      CURSOR B IS
        SELECT TIP_N_MED.DESCRIPCION
          FROM NO_MEDICO, TIPO_NO_MEDICO TIP_N_MED
         WHERE NO_MEDICO.CODIGO = FONOS_ROW.AFILIADO
           AND TIP_N_MED.CODIGO = NO_MEDICO.TIP_N_MED;

      CURSOR C IS
        SELECT POLIZA15.FEC_INI, POLIZA15.FEC_FIN
          FROM POLIZA POLIZA15
         WHERE POLIZA15.COMPANIA = FONOS_ROW.COMPANIA
           AND POLIZA15.RAMO = FONOS_ROW.RAMO
           AND POLIZA15.SECUENCIAL = FONOS_ROW.SECUENCIAL
           AND POLIZA15.FEC_VER =
               (SELECT MAX(FEC_VER)
                  FROM POLIZA POLIZA2
                 WHERE POLIZA2.COMPANIA = POLIZA15.COMPANIA
                   AND POLIZA2.RAMO = POLIZA15.RAMO
                   AND POLIZA2.SECUENCIAL = POLIZA15.SECUENCIAL
                   AND POLIZA2.FEC_VER < TRUNC(FECHA_DIA) + V_1);

      CURSOR D IS
        SELECT DESCRIPCION
          FROM CATEGORIA_ASEGURADO
         WHERE CODIGO = FONOS_ROW.CATEGORIA;

      CURSOR C_COBERTURA IS
        SELECT '1'
          FROM COB_SAL
         WHERE CODIGO = TO_NUMBER(FONOS_ROW.COBERTURA);

      -- Technocons * Victor Acevedo
      CURSOR C_FRAUDE IS
        SELECT FRAUDE
          FROM MOTIVO_ASE_DEP
         WHERE ASEGURADO = COD_ASE
           AND DEPENDIENTE = NVL(COD_DEP, 0)
           AND FRAUDE = V_S;

      --TP 09/11/2018 Enfoco
      cursor cat_medico(vreclamante number) is
        select codigo
          from medico a
         where codigo = vreclamante
           and exists (select 1
                  from med_esp_v b
                 where a.codigo = b.medico
                   and b.especialidad = V_229);

      cursor cat_n_med(vreclamante number) is
        select codigo
          from no_medico
         where codigo = vreclamante
           and tip_n_med = V_6;

      v_cat number;

      ---Enfoco mcarrion 12/02/2019
      CURSOR cur_prov_capitado IS
        Select valor_capita, afiliado
          From POLIZA_PROVEDOR p, no_medico n
         Where p.compania = FONOS_ROW.COMPANIA
           And p.ramo = FONOS_ROW.RAMO
           And p.secuencial = FONOS_ROW.SECUENCIAL
           And p.servicio = FONOS_ROW.TIP_SER
           And p.plan = FONOS_ROW.PLAN
           And n.codigo = P.AFILIADO
           And N.VALOR_CAPITA = V_1
           And p.estatus = V_46
           And p.fec_ver = (Select max(fec_ver)
                              From POLIZA_PROVEDOR a
                             Where A.COMPANIA = p.compania
                               And a.ramo = p.ramo
                               And a.secuencial = p.secuencial
                               And a.plan = p.plan);

      Cursor cap_basico(p_proveedor number) is
        Select 1
          From plan_afiliado
         Where plan = V_230 --*--
           And afiliado = p_proveedor
           And servicio = V_8 --*--
           And tip_afi IN (V_NO_MEDICO, V_MEDICO);

      Cursor nuevo(vreclamante number) is
        Select 'S'
          From Plan_Dental_nuevo p
         Where p.tip_afi = V_NO_MEDICO
           And p.afiliado = vreclamante
           And p.nuevo = V_S;


        CURSOR cur_cat_prov IS
        select a.afiliado, a.cat_pro
          from pol_pro a
         where compania = FONOS_ROW.COMPANIA
           and ramo = FONOS_ROW.RAMO
           and secuencial = FONOS_ROW.SECUENCIAL
           and plan = FONOS_ROW.PLAN
           and servicio = FONOS_ROW.TIP_SER
           and estatus = V_46
           and fec_ver = (select max(b.fec_ver)
                            FROM poliza_provedor b
                           WHERE a.compania = b.compania
                             AND a.ramo = b.ramo
                             AND a.secuencial = b.secuencial
                             AND a.plan = b.plan
                             AND a.tip_afi = b.tip_afi
                             AND a.afiliado = b.afiliado
                             AND a.servicio = b.servicio
                             );

  Cursor C_proveedor (P_COMPANIA NUMBER, P_RAMO NUMBER, P_SEC_POL NUMBER, P_PLAN NUMBER, P_SERVICIO NUMBER)
      is
   Select '1'
    From POLIZA_PROVEDOR p
    Where compania = P_COMPANIA
      And ramo     = P_RAMO
      And secuencial =  P_SEC_POL
      And plan = P_PLAN
      And servicio = P_SERVICIO;

      v_proveedor number;
      v_categoria number;
      v_cod_error number;
      --
      /* FUNCION para  Buscar Datos de la Cobertura */
      FUNCTION BUSCAR_DATOS_COBERTURA(VAR_TIP_SER    IN INFOX_SESSION.TIP_SER%TYPE,
                                      VAR_COBERTURA  IN INFOX_SESSION.COBERTURA%TYPE,
                                      VAR_TIP_REC    IN INFOX_SESSION.TIP_REC%TYPE,
                                      VAR_RECLAMANTE IN INFOX_SESSION.AFILIADO%TYPE,
                                      VAR_TIP_SER2   IN OUT INFOX_SESSION.TIP_SER%TYPE,
                                      VAR_TIP_COB    IN OUT REC_C_SAL.TIP_COB%TYPE,
                                      VAR_DSP4       IN OUT SER_SAL.DESCRIPCION%TYPE,
                                      VAR_DSP2       IN OUT TIP_C_SAL.DESCRIPCION%TYPE,
                                      VAR_DSP3       IN OUT COB_SAL.DESCRIPCION%TYPE,
                                      NO_M_LIM_AFI   IN OUT NO_M_COB.LIMITE%TYPE,
                                      NO_M_POR_DES   IN OUT NO_M_COB.POR_DES%TYPE)
      --VAR_FEC_VER    IN DATE DEFAULT SYSDATE,--
        --VAR_CAT_N_MED  IN INFOX_SESSION.CAT_N_MED%TYPE,--
        --VAR_DAT_ASEG IN C_DAT_ASEG%ROWTYPE )--
       RETURN NUMBER IS
        ERROR CHAR(1) := NULL;
      BEGIN
        p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

        IF FONOS_ROW.TIP_REC = 'ASEGURADO' THEN
          ERROR := Paq_Matriz_Validaciones.Datos_Cobertura_Asegurados(var_tip_ser,
                                                                      var_cobertura,
                                                                      var_tip_ser2,
                                                                      var_tip_cob,
                                                                      var_dsp4,
                                                                      var_dsp2,
                                                                      var_dsp3);

        ELSIF FONOS_ROW.TIP_REC = 'NO_MEDICO' THEN
          ERROR := Paq_Matriz_Validaciones.Datos_Cobertura_No_Medico(FONOS_ROW.COMPANIA,
                                                                     FONOS_ROW.RAMO,
                                                                     FONOS_ROW.SECUENCIAL,
                                                                     var_reclamante,
                                                                     var_tip_ser,
                                                                     fonos_row.PLAN,
                                                                     var_cobertura,
                                                                     var_tip_ser2,
                                                                     var_tip_cob,
                                                                     var_dsp4,
                                                                     var_dsp2,
                                                                     var_dsp3,
                                                                     no_m_lim_afi,
                                                                     no_m_por_des);

        ELSIF FONOS_ROW.TIP_REC = 'MEDICO' THEN
          ERROR := Paq_Matriz_Validaciones.Datos_Cobertura_Medico(FONOS_ROW.COMPANIA,
                                                                  FONOS_ROW.RAMO,
                                                                  FONOS_ROW.SECUENCIAL,
                                                                  var_reclamante,
                                                                  --VAR_CAT_N_MED,
                                                                  var_tip_ser,
                                                                  fonos_row.PLAN,
                                                                  var_cobertura,
                                                                  var_tip_ser2,
                                                                  var_tip_cob,
                                                                  var_dsp4,
                                                                  var_dsp2,
                                                                  var_dsp3,
                                                                  no_m_lim_afi,
                                                                  no_m_por_des);
        END IF;
        RETURN(ERROR);
      END;

      PROCEDURE Calcular_Reserva(LIM_AFI     IN NO_M_COB.LIMITE%TYPE,
                                 POR_DES     IN NO_M_COB.POR_DES%TYPE,
                                 POR_COA     IN POL_P_SER.POR_COA%TYPE,
                                 MON_PAG     IN OUT REC_C_SAL.MON_PAG%TYPE,
                                 MON_POR_COA IN OUT INFOX_SESSION.MON_PAG%TYPE,
                                 P_MON_EXE   IN NUMBER,
                                 P_MON_ACUM  IN NUMBER) IS
      BEGIN
        IF P_MON_EXE IS NOT NULL AND P_MON_EXE <> 0 THEN
          IF P_MON_ACUM > P_MON_EXE THEN
            MON_POR_COA := ROUND((LIM_AFI * POR_COA / 100), 2);
          ELSIF (P_MON_ACUM + LIM_AFI) > P_MON_EXE THEN
            MON_POR_COA := ROUND(((((LIM_AFI + P_MON_ACUM) - P_MON_EXE) *
                                 POR_COA) / 100),
                                 2);
          END IF;
          MON_PAG := (LIM_AFI - NVL(MON_POR_COA, 0));
        ELSE
          MON_POR_COA := ROUND((LIM_AFI * POR_COA / 100), 2);
          MON_PAG     := (LIM_AFI - NVL(MON_POR_COA, 0));
        END IF;
      END;
      /* Rutina Principal */
    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

      fecha_dia := TO_DATE(TO_CHAR(SYSDATE, 'dd/mm/yyyy'), 'dd/mm/yyyy');
      OPEN A;
      FETCH A
        INTO FONOS_ROW.TIP_REC,
             FONOS_ROW.AFILIADO,
             FONOS_ROW.TIP_COB,
             FONOS_ROW.COBERTURA,
             FONOS_ROW.COMPANIA,
             FONOS_ROW.RAMO,
             FONOS_ROW.SECUENCIAL,
             FONOS_ROW.PLAN,
             FONOS_ROW.ASEGURADO,
             FONOS_ROW.DEPENDIENTE,
             FONOS_ROW.SEXO,
             FONOS_ROW.FEC_ING,
             FONOS_ROW.FEC_NAC,
             FONOS_ROW.ANO_REC,
             FONOS_ROW.SEC_REC,
             FONOS_ROW.CATEGORIA,
             FONOS_ROW.EST_CIV,
             FONOS_ROW.MON_REC_AFI,
             FONOS_ROW.CAT_N_MED,
             FONOS_ROW.TIP_SER;
      IF A%FOUND THEN
        OPEN D;
        FETCH D
          INTO VAR_CATEGORIA;
        CLOSE D;
        --
        COD_ASE := TO_NUMBER(FONOS_ROW.ASEGURADO);
        COD_DEP := TO_NUMBER(FONOS_ROW.DEPENDIENTE);
        --
        IF NVL(COD_DEP, 0) = 0 THEN
          VAR_TIP_A_USO := 'ASEGURADO';
        ELSE
          VAR_TIP_A_USO := 'DEPENDIENT';
        END IF;
        --
        IF FONOS_ROW.TIP_REC = 'NO_MEDICO' THEN
          OPEN B;
          FETCH B
            INTO DES_TIP_N_MED;
          CLOSE B;
        ELSE
          DES_TIP_N_MED := FONOS_ROW.TIP_REC;
        END IF;
        --
        OPEN C;
        FETCH C
          INTO VAR_FEC_INI, VAR_FEC_FIN;
        CLOSE C;
        --
        /*codigo nuevo*/
        V_INSER := TO_NUMBER(SUBSTR(P_INSTR1, 1, 2));
        V_INTIP := TO_NUMBER(SUBSTR(P_INSTR1, 3, 2));
        V_INCOB := SUBSTR(P_INSTR1, 5, 10);
        --

        IF V_INTIP = 6 THEN
          V_INSER := 8; --TP 09/11/2018
          --<00062> jdeveaux 27nov2017 Se valida la red dental del afiliado para determinar servicio
          /*V_RED_PLAT := DBAPER.F_VALIDA_RED_DENTAL_PLATINUM(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, V_MSG);
          IF  V_RED_PLAT = 8 THEN
               V_INSER :=  V_RED_PLAT;
          ELSE
               V_INSER := 1;
          END IF;*/
          --</00062>
        ELSIF V_INTIP > 7 AND V_INTIP <> 76 THEN
          V_INSER := 3;
        ELSE
          V_INSER := 1;
        END IF;

        --TP 09/11/2018 Enfoco
        if FONOS_ROW.TIP_REC = 'MEDICO' then
          open cat_medico(FONOS_ROW.AFILIADO);
          fetch cat_medico
            into v_cat;
          if cat_medico%found then
            V_INSER := 8;
          end if;
          close cat_medico;
        else
          open cat_n_med(FONOS_ROW.AFILIADO);
          fetch cat_n_med
            into v_cat;
          if cat_n_med%found then
            V_INSER := 8;
          end if;
          close cat_n_med;
        end if;
        --TP 09/11/2018 Enfoco

         --Miguel A. Carrion se agrego cursor para validar si el afiliado posee un proveedor de odontologia 21/07/2020
         ---Miguel Carrion 04/11/2022
         IF V_INSER  = DBAPER.BUSCA_PARAMETRO('ODONTOLOGIA',FONOS_ROW.COMPANIA) THEN
          --
                Open C_proveedor(FONOS_ROW.COMPANIA,FONOS_ROW.RAMO,FONOS_ROW.SECUENCIAl,FONOS_ROW.PLAN,V_INSER);
               Fetch C_proveedor Into v_proveedor;
              If C_proveedor%Notfound and (not VALIDA_RECLAMANTE(FONOS_ROW.AFILIADO)) Then
                  --
                  --
                  v_cod_error := 2;
                  --
                  --
              End If;
           --
          Close C_proveedor;
         --
         END IF;

        --SI AUN NO SE HA GENERADO UNA RECLAMACION TOMA EL SERVICIO DEL VALOR DIGITADO--
        --EN CASO CONTRARIO TOMA EL SERVICIO DE LA RECLAMACION YA INSERTADA--
        IF (NVL(FONOS_ROW.SEC_REC, 0) = 0) THEN
          FONOS_ROW.TIP_SER := V_INSER;
        END IF;
        FONOS_ROW.TIP_COB   := V_INTIP;
        FONOS_ROW.COBERTURA := V_INCOB;
        var_tip_ser2        := FONOS_ROW.TIP_SER;
        --
        --Enfoco mcarrion 12/02/2019
        if FONOS_ROW.TIP_REC = 'NO_MEDICO' and FONOS_ROW.TIP_SER = 8 then

          OPEN cur_prov_capitado;
          FETCH cur_prov_capitado
            INTO v_prov_capitado, v_prov_basico;
          CLOSE cur_prov_capitado;

          OPEN cap_basico(v_prov_basico);
          FETCH cap_basico
            INTO v_prov_existe;
          CLOSE cap_basico;

          OPEN nuevo(FONOS_ROW.AFILIADO);
          FETCH nuevo
            into v_nuevo;
          CLOSE nuevo;

          IF v_prov_capitado = 1 and NVL(v_prov_existe, 0) = 0 and
             nvl(v_nuevo, 'N') = 'N' then
            --
            var_code := 2; --MSG_ALERT('Afiliado tiene un plan capitado, no debe pasar reclamaciones.','E', TRUE);
            --
           ELSE
             --
               ---Miguel Carrion 04/11/2022
           IF ((FONOS_ROW.TIP_REC = 'NO_MEDICO' AND
                 FONOS_ROW.TIP_SER = DBAPER.BUSCA_PARAMETRO('ODONTOLOGIA',FONOS_ROW.COMPANIA)) OR
                 (FONOS_ROW.TIP_REC = 'MEDICO' AND FONOS_ROW.TIP_SER = DBAPER.BUSCA_PARAMETRO('ODONTOLOGIA',FONOS_ROW.COMPANIA))) THEN

                OPEN cur_cat_prov;
                FETCH cur_cat_prov
                  INTO v_proveedor, v_categoria;
                CLOSE cur_cat_prov;

              END IF;
            --
          END IF;

        end if;
        ---Enfoco mcarrion 12/02/2019

        /*PROCEDIMIENTO PARA PROBAR
        FONOS_ROW.COBERTURA := P_INSTR1;
          FONOS_ROW.TIP_COB   := 5;
          FONOS_ROW.TIP_SER   := 1;*/
        IF nvl(COD_ASE, 0) = 0 THEN
          var_code := 1;
        END IF;
        --  IF VAR_CODE IS NULL OR VAR_CODE <> 2 THEN
        IF nvl(COD_ASE, 0) <> 0 THEN
          OPEN C_COBERTURA;
          FETCH C_COBERTURA
            INTO DUMMY;
          IF C_COBERTURA%NOTFOUND THEN
            ERROR := '1';
          END IF;
          CLOSE C_COBERTURA;
          IF ERROR IS NULL THEN
            error := BUSCAR_DATOS_COBERTURA(FONOS_ROW.TIP_SER,
                                            FONOS_ROW.COBERTURA,
                                            FONOS_ROW.TIP_REC,
                                            FONOS_ROW.AFILIADO,
                                            VAR_TIP_SER2,
                                            FONOS_ROW.TIP_COB,
                                            SER_SAL_ROW.DESCRIPCION,
                                            TIP_C_SAL_ROW.DESCRIPCION,
                                            COB_SAL_ROW.DESCRIPCION,
                                            NO_M_COB_ROW.LIMITE,
                                            NO_M_COB_ROW.POR_DES);

            --<jdeveaux 18may2016>
            /*Procedimiento para validar si el prestador de servicios se encuentra en la red del plan basico si no esta en la red de la poliza voluntario.*/
            /*Si se da esta condicion, todas las validaciones posteriores de coberturas deben hacerse bajo la configuracion del plan basico (ramo, secuencial, plan)*/
            DECLARE
              RED_VOLUNTARIO     BOOLEAN;
              RED_EXCEPCION_ODON BOOLEAN;
              RED_PBS            BOOLEAN;
              V_PLAN_PBS         NUMBER(3);
              V_COMPANIA_PBS     NUMBER(2);
              V_RAMO_PBS         NUMBER(2);
              V_SEC_PBS          NUMBER(7);

            BEGIN
              --Se limpian las variables
              V_PLAN_PBS     := null;
              V_COMPANIA_PBS := null;
              V_RAMO_PBS     := null;
              V_SEC_PBS      := null;
              --
              --Solo debe funcionar para las polizas voluntarias
              IF FONOS_ROW.RAMO = 95 THEN
                --Valida si el proveedor pertenece a la red del plan voluntario
                RED_VOLUNTARIO := Paq_Matriz_Validaciones.Validar_Plan_Afiliado(fonos_row.PLAN,
                                                                                fonos_row.tip_ser,
                                                                                fonos_row.tip_rec,
                                                                                FONOS_ROW.AFILIADO);

                --MCARRION 26/06/2019
                RED_EXCEPCION_ODON := DBAPER.EXCEPCION_POLIZA_ODON(FONOS_ROW.COMPANIA,
                                                                   FONOS_ROW.RAMO,
                                                                   FONOS_ROW.SECUENCIAL,
                                                                   FONOS_ROW.TIP_SER);

                IF (NOT (RED_VOLUNTARIO) AND NOT (RED_EXCEPCION_ODON)
                AND/*(V_INSER = 13)*/ V_SIMULTANEO = 'S') OR (V_INSER = DBAPER.BUSCA_PARAMETRO('TIP_SERV_CONS_MEDI_0',FONOS_ROW.COMPANIA) AND V_SIMULTANEO = 'S') THEN

                    --Miguel Carrion 04/11/2022
                     IF (VALIDA_RECLAMANTE(FONOS_ROW.AFILIADO)) THEN
                      v_proveedor := null;
                    END IF;

                  --DBMS_OUTPUT.PUT_LINE('RED_VOLUNTARIO 2 ');
                  --Busca los datos de la poliza del plan basico
                  DBAPER.POLIZA_PLAN_BASICO(V_COMPANIA_PBS,
                                            V_RAMO_PBS,
                                            V_SEC_PBS,
                                            V_PLAN_PBS);
                  --Valida si el proveedor pertenece a la red del plan basico
                  RED_PBS := Paq_Matriz_Validaciones.Validar_Plan_Afiliado(V_PLAN_PBS,
                                                                           fonos_row.tip_ser,
                                                                           fonos_row.tip_rec,
                                                                           FONOS_ROW.AFILIADO);

                  IF RED_PBS THEN
                    --Guarda en variables los datos originales de la poliza voluntaria
                    V_PLAN_ORI     := FONOS_ROW.PLAN;
                    V_COMPANIA_ORI := FONOS_ROW.COMPANIA;
                    V_RAMO_ORI     := FONOS_ROW.RAMO;
                    V_SEC_ORI      := FONOS_ROW.SECUENCIAL;

                    --Cambia los datos de poliza y plan a los del Plan Basico. Esto debe ser restaurado antes de salir de VALIDATECOBERTURA
                    FONOS_ROW.PLAN       := V_PLAN_PBS;
                    FONOS_ROW.COMPANIA   := V_COMPANIA_PBS;
                    FONOS_ROW.RAMO       := V_RAMO_PBS;
                    FONOS_ROW.SECUENCIAL := V_SEC_PBS;
                  END IF;
                END IF;
              END IF;
            END;
            --</jdeveaux>

            IF ERROR IS NULL THEN
              -- Enfoco - 05/11/2018
              Paq_Matriz_Validaciones.BUSCA_RANGOS_COBERTURA(FONOS_ROW.PLAN,
                                                             FONOS_ROW.TIP_SER,
                                                             FONOS_ROW.TIP_COB,
                                                             P_RAN_U_EXC,
                                                             P_RAN_U_MAX);
              /* ---------------------------------------------------------------------- */
              /*   Determina Origen de la Cobertura                                      */
              /* ---------------------------------------------------------------------- */
              --
              OPEN C_PLAN_EXCEPTION;
              FETCH C_PLAN_EXCEPTION
                INTO M_PLAN_EXCEPTION;
              CLOSE C_PLAN_EXCEPTION;

              OPEN C_VALIDA_PLAN_EXCENTO(FONOS_ROW.PLAN, M_PLAN_EXCEPTION);
              FETCH C_VALIDA_PLAN_EXCENTO
                INTO M_VALIDA_PLAN;
              IF C_VALIDA_PLAN_EXCENTO%NOTFOUND THEN
                IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then

                  ORI_FLAG := Paq_Matriz_Validaciones.Busca_Origen_Cob(FONOS_ROW.TIP_SER,
                                                                       FONOS_ROW.TIP_COB,
                                                                       FONOS_ROW.COBERTURA,
                                                                       vUsuario,
                                                                       FONOS_ROW.RAMO,
                                                                       FONOS_ROW.COMPANIA);
                  IF ORI_FLAG IS NOT NULL THEN
                    ERROR := '1';
                  END IF;

                  IF ERROR IS NOT NULL THEN
                    vESTUDIO_REPETICION := BUSCA_COB_ESTUDIO_REPETICION(FONOS_ROW.ASEGURADO,
                                                                        FONOS_ROW.DEPENDIENTE,
                                                                        FONOS_ROW.COMPANIA,
                                                                        FONOS_ROW.RAMO,
                                                                        FONOS_ROW.SECUENCIAL,
                                                                        FONOS_ROW.TIP_SER,
                                                                        FONOS_ROW.TIP_COB,
                                                                        FONOS_ROW.COBERTURA,
                                                                        vUsuario);

                    IF NVL(vESTUDIO_REPETICION, 'N') = 'S' THEN
                      ERROR := NULL;
                    END IF;
                  END IF;

                  IF ERROR IS NULL THEN
                    -- Htorres - 29/09/2019
                    -- Monto maximo que se pueda otorgar para esa cobertura por canales
                    vMON_MAX_COB_ORIGEN := BUSCA_ORIGEN_COB_MON_MAX(FONOS_ROW.TIP_SER,
                                                                    FONOS_ROW.TIP_COB,
                                                                    FONOS_ROW.COBERTURA,
                                                                    vUsuario);
                  END IF;
                END IF;
              END IF;
              CLOSE C_VALIDA_PLAN_EXCENTO;

              IF ERROR IS NULL THEN
                /* --------------------------------------------------------------------- */
                /* --------------------------------------------------------------------- */
                /*  Busca Limite de monto por cobertura de salud                         */
                /* --------------------------------------------------------------------- */
               IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then
                  --
                  LIMITE_LABORATORIO := Paq_Matriz_Validaciones.Tip_Cob_Mon_Max(FONOS_ROW.COMPANIA,
                                                                                FONOS_ROW.RAMO,
                                                                                FONOS_ROW.SECUENCIAL,
                                                                                FONOS_ROW.PLAN,
                                                                                FONOS_ROW.TIP_SER,
                                                                                FONOS_ROW.TIP_COB,
                                                                                P_MON_EXE,
                                                                                P_UNI_T_EXE,
                                                                                P_RAN_EXE,
                                                                                P_POR_COA,
                                                                                P_UNI_T_MAX);
                  --
                END IF;
                --
                --P_MON_DED_TIP_COB);
                /* --------------------------------------------------------------------- */
                /* Valida que el Asegurado puede Recibir la Cobertura de Salud.          */
                /* --------------------------------------------------------------------- */
                error := Paq_Matriz_Validaciones.CHK_COBERTURA_ASEGURADO_FONO(TRUE,
                                                                              FONOS_ROW.TIP_REC,
                                                                              FONOS_ROW.AFILIADO,
                                                                              DES_TIP_N_MED,
                                                                              VAR_TIP_A_USO,
                                                                              COD_ASE,
                                                                              COD_DEP,
                                                                              FONOS_ROW.COMPANIA,
                                                                              FONOS_ROW.RAMO,
                                                                              FONOS_ROW.SECUENCIAL,
                                                                              FONOS_ROW.PLAN,
                                                                              FONOS_ROW.TIP_SER,
                                                                              FONOS_ROW.TIP_COB,
                                                                              FONOS_ROW.COBERTURA,
                                                                              VAR_TIP_SER2,
                                                                              FECHA_DIA,
                                                                              FONOS_ROW.SEXO,
                                                                              FONOS_ROW.EST_CIV,
                                                                              VAR_CATEGORIA,
                                                                              FONOS_ROW.FEC_NAC,
                                                                              POR_COA,
                                                                              NO_M_COB_ROW.LIMITE,
                                                                              PLA_STC_ROW.FRECUENCIA,
                                                                              PLA_STC_ROW.UNI_TIE_F,
                                                                              PLA_STC_ROW.TIE_ESP,
                                                                              PLA_STC_ROW.UNI_TIE_T,
                                                                              PLA_STC_ROW.MON_MAX, --A--
                                                                              PLA_STC_ROW.UNI_TIE_M,
                                                                              PLA_STC_ROW.SEXO,
                                                                              PLA_STC_ROW.EDA_MIN,
                                                                              PLA_STC_ROW.EDA_MAX,
                                                                              P_DSP_EST_CIV,
                                                                              P_DSP_CATEGORIA,
                                                                              MONTO_CONTRATADO,
                                                                              vUsuario,
                                                                              P_POR_COA,
                                                                              P_MONTO_MAX, --A estaba dos veces--
                                                                              PLA_STC_ROW.EXC_MCA,
                                                                              PLA_STC_ROW.MON_DED,
                                                                                v_categoria,
                                                                                v_proveedor);



                IF ERROR IS NULL THEN
                  /*---------------------------------------------------------- */
                  /* Valida que no se este digitando una Reclamacion           */
                  /* que ya fue reclamada por el mismo.                        */
                  /* --------------------------------------------------------- */
                  SEC_RECLAMACION := Paq_Matriz_Validaciones.Valida_Rec_Fecha_Null(TRUE,
                                                                                   VAR_ESTATUS_CAN,
                                                                                   FONOS_ROW.ANO_REC,
                                                                                   FONOS_ROW.COMPANIA,
                                                                                   V_RAMO_ORI, -- FONOS_ROW.RAMO,      -- V_RAMO_ORI Reclamaciones Duplicadas (Victor Acevedo)
                                                                                   FONOS_ROW.SEC_REC,
                                                                                   FONOS_ROW.TIP_REC,
                                                                                   FONOS_ROW.AFILIADO,
                                                                                   VAR_TIP_A_USO,
                                                                                   COD_ASE,
                                                                                   COD_DEP,
                                                                                   FONOS_ROW.TIP_SER,
                                                                                   FONOS_ROW.TIP_COB,
                                                                                   FONOS_ROW.COBERTURA,
                                                                                   FECHA_DIA);
                  IF SEC_RECLAMACION IS NOT NULL THEN
                    ERROR := '1';
                  END IF;
                  --
                  IF ERROR IS NULL THEN
                    /* ---------------------------------------------------------- */
                    /* Valida que no se este digitando una Reclamacion            */
                    /* que ya fue reclamada por otro que participo en la          */
                    /* aplicacion de la Cobertura.                                */
                    /* ---------------------------------------------------------- */
                    error := Paq_Matriz_Validaciones.Valida_Rec_C_Sal_Fec(TRUE,
                                                                          VAR_ESTATUS_CAN,
                                                                          FONOS_ROW.ANO_REC,
                                                                          FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SEC_REC,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VAR_TIP_A_USO,
                                                                          COD_ASE,
                                                                          COD_DEP,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FECHA_DIA);
                    IF ERROR IS NULL THEN
                      /* ---------------------------------------------------------- */
                      /* Valida:                                                    */
                      /* 1-) Tiempo de Espera de la Cobertura                       */
                      /* ---------------------------------------------------------- */
                      error := Paq_Matriz_Validaciones.Validar_Tiempo_Espera(TRUE,
                                                                             FECHA_DIA,
                                                                             --VAR_FEC_INI,
                                                                             FONOS_ROW.FEC_ING,
                                                                             PLA_STC_ROW.TIE_ESP,
                                                                             PLA_STC_ROW.UNI_TIE_T);

                      IF ERROR IS NULL OR ERROR = '0' -- Caso # 14282
                       THEN
                        /* ---------------------------------------------------------- */
                        /* Valida:                                                    */
                        /* 1-) Cobertura No Exceda la Frecuencia de Uso para su       */
                        /*     Tipo de Cobertura.                                     */
                        /* ---------------------------------------------------------- */
                        /* ***** SOLO Aplica para Tipo_Coberturas:LABORATORIOS ****** */
                        /* ***** en Servicios:AMBULATORIO                      ****** */
                        /* ---------------------------------------------------------- */
                       IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then
                          --
                          error := Paq_Matriz_Validaciones.Validar_Frec_Tip_Cob(TRUE,
                                                                                VAR_ESTATUS_CAN,
                                                                                VAR_TIP_A_USO,
                                                                                COD_ASE,
                                                                                COD_DEP,
                                                                                FONOS_ROW.PLAN,
                                                                                FONOS_ROW.TIP_SER,
                                                                                FONOS_ROW.TIP_COB,
                                                                                FONOS_ROW.COBERTURA,
                                                                                FECHA_DIA,
                                                                                VAR_FEC_INI,
                                                                                FONOS_ROW.COMPANIA,
                                                                                FONOS_ROW.RAMO,
                                                                                FONOS_ROW.SECUENCIAL,
                                                                                DSP_COB_LAB,
                                                                                DSP_FREC_TIP_COB);
                          --
                        END IF;
                        --
                        IF ERROR IS NULL THEN
                          /* ---------------------------------------------------------- */
                          /* Valida que en las Reclamaciones:                           */
                          /* 1-) Cobertura No Exceda la Frecuencia de Uso               */
                          /* 2-) Cobertura No Exceda los Montos Maximo.                 */
                          /* ---------------------------------------------------------- */
                          IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then
                            --
                            error := Paq_Matriz_Validaciones.Validar_Frec_Cobertura(TRUE,
                                                                                    VAR_ESTATUS_CAN,
                                                                                    VAR_TIP_A_USO,
                                                                                    COD_ASE,
                                                                                    COD_DEP,
                                                                                    FONOS_ROW.TIP_SER,
                                                                                    FONOS_ROW.TIP_COB,
                                                                                    FONOS_ROW.COBERTURA,
                                                                                    FECHA_DIA,
                                                                                    VAR_FEC_INI,
                                                                                    FONOS_ROW.FEC_ING,
                                                                                    PLA_STC_ROW.FRECUENCIA,
                                                                                    PLA_STC_ROW.UNI_TIE_F,
                                                                                    PLA_STC_ROW.TIE_ESP,
                                                                                    PLA_STC_ROW.UNI_TIE_T,
                                                                                    PLA_STC_ROW.MON_MAX,
                                                                                    PLA_STC_ROW.UNI_TIE_M,
                                                                                    FONOS_ROW.COMPANIA,
                                                                                    DSP_FREC_ACUM,
                                                                                    DSP_MON_PAG_ACUM,
                                                                                    FONOS_ROW.PLAN);
                            --
                          END IF;
                          --
                          IF ERROR IS NULL THEN
                            /* --------------------------------------------------- */
                            /* Determina el limite de frecuencia paralelo          */
                            /* por plan por tipo de cobertura                      */
                            /* --------------------------------------------------- */
                            IF 
                      Paq_Matriz_Validaciones.F_POLIZA_EXENTO_RESTRICCION(FONOS_ROW.COMPANIA,
                                                                          FONOS_ROW.RAMO,
                                                                          FONOS_ROW.SECUENCIAL,
                                                                          FONOS_ROW.PLAN,
                                                                          FONOS_ROW.TIP_SER,
                                                                          FONOS_ROW.TIP_COB,
                                                                          FONOS_ROW.COBERTURA,
                                                                          FONOS_ROW.TIP_REC,
                                                                          FONOS_ROW.AFILIADO,
                                                                          VUSUARIO) = false then
                              --
                              ERROR := Paq_Matriz_Validaciones.validar_frec_tip_cob_fono(p_field_level     => TRUE,
                                                                                         p_var_estatus_can => VAR_ESTATUS_CAN, -- Cancelada en la Rec
                                                                                         p_tip_a_uso       => VAR_TIP_A_USO,
                                                                                         p_ase_uso         => COD_ASE,
                                                                                         p_dep_uso         => COD_DEP,
                                                                                         p_plan            => FONOS_ROW.PLAN,
                                                                                         p_servicio        => FONOS_ROW.TIP_SER,
                                                                                         p_tip_cob         => FONOS_ROW.TIP_COB,
                                                                                         p_cobertura       => FONOS_ROW.COBERTURA,
                                                                                         p_fec_ser         => FECHA_DIA,
                                                                                         p_fec_ini_pol     => VAR_FEC_INI,
                                                                                         p_fec_ing         => FONOS_ROW.FEC_ING,
                                                                                         p_frecuencia      => var_frecuencia,
                                                                                         p_uni_tie_f       => var_uni_tie_f,
                                                                                         p_tie_esp         => PLA_STC_ROW.TIE_ESP,
                                                                                         p_uni_tie_t       => PLA_STC_ROW.UNI_TIE_T,
                                                                                         p_mon_max         => PLA_STC_ROW.MON_MAX,
                                                                                         p_uni_tie_m       => PLA_STC_ROW.UNI_TIE_M,
                                                                                         p_dsp_frec_acum   => var_dsp_frec_acum);

                              --
                            END IF;

                            --
                            IF ERROR IS NULL THEN
                              /* ---------------------------------------------------  */
                              /* Determina si el afiliado digita el Monto a Reclamar  */
                              /* para igualar el limite al monto digitado             */
                              /* ---------------------------------------------------  */
                              --VIA FONOSALUD EL AFILIADO NO DIGITA NINGUN MONTO A RECLAMAR--
                              --VIA POS EL AFILIADO DIGITA EL MONTO A RECLAMAR--
                              IF NVL(to_number(p_instr2), 0) > 0 THEN
                                IF NVL(to_number(p_instr2), 0) <
                                   NO_M_COB_ROW.LIMITE THEN
                                  FONOS_ROW.MON_REC_AFI := to_number(p_instr2);
                                ELSE
                                  FONOS_ROW.MON_REC_AFI := NO_M_COB_ROW.LIMITE;
                                END IF;
                              END IF;
                              IF FONOS_ROW.MON_REC_AFI IS NOT NULL AND
                                 FONOS_ROW.MON_REC_AFI <> 0 THEN
                                NO_M_COB_ROW.LIMITE := FONOS_ROW.MON_REC_AFI;
                              END IF;
                              /*-------------------------------------------------------------- */
                              /* Buscar monto acumulados de reclamaciones en periodo de tiempo,*/
                              /* si tiene monto excento por tipo de cobertura                  */
                              /*-------------------------------------------------------------- */
                              P_MON_ACUM := 0;
                              IF P_MON_EXE IS NOT NULL AND P_MON_EXE <> 0 THEN
                                /* -----------------------------------------------------------------------  */
                                /* Obtiene la Fecha Inicial segun la Unidad de Tiempo                       */
                                /* de monto excento para determinar si ha excedido el Uso de la Cobertura.  */
                                /* -----------------------------------------------------------------------  */
                                T_FEC_INI := Paq_Matriz_Validaciones.Determina_Fecha_Rango(FECHA_DIA,
                                                                                           VAR_FEC_INI,
                                                                                           NULL,
                                                                                           NULL,
                                                                                           NULL,
                                                                                           P_RAN_U_EXC,
                                                                                           P_MON_EXE,
                                                                                           NVL(P_UNI_T_EXE,
                                                                                               365));
                                /* ----------------------------------------------------------------------  */
                                /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto excento   */
                                /* para determinar si ha excedido el Uso excento de la Cobertura.          */
                                /* ----------------------------------------------------------------------  */
                                T_FEC_FIN := Paq_Matriz_Validaciones.Determina_Fecha_Rango_Fin(FECHA_DIA,
                                                                                               VAR_FEC_INI,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               P_MON_EXE,
                                                                                               NVL(P_UNI_T_EXE,
                                                                                                   365),
                                                                                               P_RAN_U_EXC);
                                /* Si la Fecha Fin es null, entonces sera igual */
                                /* a la Fecha de Servicio.      */
                                IF T_FEC_FIN IS NULL THEN
                                  T_FEC_FIN := FECHA_DIA;
                                END IF;
                                P_MON_ACUM := Paq_Matriz_Validaciones.Buscar_Rec_Acumuladas(VAR_TIP_A_USO,
                                                                                            COD_ASE,
                                                                                            COD_DEP,
                                                                                            FECHA_DIA,
                                                                                            FONOS_ROW.COMPANIA,
                                                                                            FONOS_ROW.RAMO,
                                                                                            FONOS_ROW.PLAN,
                                                                                            FONOS_ROW.TIP_SER,
                                                                                            FONOS_ROW.TIP_COB,
                                                                                            VAR_ESTATUS_CAN,
                                                                                            T_FEC_INI,
                                                                                            T_FEC_FIN);
                              END IF;
                              /* ------------------------------------------------------------- */
                              /* Procedure que llama los program unit que realizan el          */
                              /* Calculo de la Reserva.                                        */
                              /* ------------------------------------------------------------- */
                              Calcular_Reserva(NO_M_COB_ROW.LIMITE,
                                               NO_M_COB_ROW.POR_DES,
                                               POR_COA,
                                               FONOS_ROW.MON_PAG,
                                               FONOS_ROW.MON_DED,
                                               P_MON_EXE,
                                               P_MON_ACUM);

                              /* --Htorres
                              Paq_Matriz_Validaciones.CALCULAR_RESERVA(
                                    NO_M_COB_ROW.LIMITE, --FONOS_ROW.MON_REC_AFI,
                                    NO_M_COB_ROW.LIMITE,
                                    PLA_STC_ROW.FRECUENCIA,
                                    POR_COA,
                                    NO_M_COB_ROW.POR_DES,
                                    P_RESERVA,
                                    fonos_row.mon_pag,
                                    PLA_STC_ROW.MON_MAX,
                                    P_MON_ACUM,
                                    FONOS_ROW.MON_DED --PLA_STC_ROW.MON_DED
                                    );   */
                              --
                              MONTO_LABORATORIO := 0;
                              --
                              IF LIMITE_LABORATORIO IS NOT NULL AND
                                 LIMITE_LABORATORIO <> 0 THEN
                                -- Si tiene limite monto maximo por tipo de cobertura, entonces procede a buscar monto acumulado  --
                                /* ---------------------------------------------------------- */
                                /* Valida:                                                    */
                                /* 1-) Cobertura No Exceda el Monto a Pagar para Tipo de      */
                                /*     Cobertura de Laboratorio y Rayos X en Ambulatorios.    */
                                /* ---------------------------------------------------------- */
                                /* -----------------------------------------------------------------------  */
                                /* Obtiene la Fecha Inicial segun la Unidad de Tiempo                       */
                                /* de monto maximo para determinar si ha excedido el Uso de la Cobertura.  */
                                /* -----------------------------------------------------------------------  */
                                T_FEC_INI := Paq_Matriz_Validaciones.Determina_Fecha_Rango(FECHA_DIA,
                                                                                           VAR_FEC_INI,
                                                                                           NULL,
                                                                                           NULL,
                                                                                           NULL,
                                                                                           P_RAN_U_EXC,
                                                                                           LIMITE_LABORATORIO,
                                                                                           NVL(P_UNI_T_MAX,
                                                                                               365));
                                /* ----------------------------------------------------------------------  */
                                /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto maximo  */
                                /* para determinar si ha excedido el Uso maximo de la Cobertura.          */
                                /* ----------------------------------------------------------------------  */
                                T_FEC_FIN := Paq_Matriz_Validaciones.Determina_Fecha_Rango_Fin(FECHA_DIA,
                                                                                               VAR_FEC_INI,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               NULL,
                                                                                               LIMITE_LABORATORIO,
                                                                                               NVL(P_UNI_T_MAX,
                                                                                                   365),
                                                                                               P_RAN_U_EXC);
                                /* Si la Fecha Fin es null, entonces sera igual
                                */
                                /* a la Fecha de Servicio.     */
                                IF T_FEC_FIN IS NULL THEN
                                  T_FEC_FIN := FECHA_DIA;
                                END IF;
                                --
                                MONTO_LABORATORIO := Paq_Matriz_Validaciones.Validar_Lab_Rayos(VAR_TIP_A_USO,
                                                                                               COD_ASE,
                                                                                               COD_DEP,
                                                                                               FECHA_DIA,
                                                                                               FONOS_ROW.COMPANIA,
                                                                                               FONOS_ROW.RAMO,
                                                                                               FONOS_ROW.SECUENCIAL,
                                                                                               FONOS_ROW.PLAN,
                                                                                               FONOS_ROW.TIP_SER,
                                                                                               FONOS_ROW.TIP_COB,
                                                                                               FONOS_ROW.COBERTURA,
                                                                                               VAR_ESTATUS_CAN,
                                                                                               T_FEC_INI,
                                                                                               T_FEC_FIN);
                                --
                                MONTO_LABORATORIO := MONTO_LABORATORIO + FONOS_ROW.MON_PAG;
                                IF MONTO_LABORATORIO > LIMITE_LABORATORIO THEN
                                  ERROR := '1';
                                END IF;
                                --
                              END IF; /*END LIMITE_LABORATORIO IS NOT NULL*/

                              -- Htorres - 29/09/2019
                              -- Monto maximo que se pueda otorgar para esa cobertura por canales
                              IF NVL(vMON_MAX_COB_ORIGEN, 0) > 0 AND
                                 (FONOS_ROW.MON_PAG > vMON_MAX_COB_ORIGEN) THEN
                                ERROR := '1';
                              END IF;
                              --
                              IF ERROR IS NULL THEN
                                /***************************************************/
                                /*    Validar que el afiliado pueda reclamar en el plan del asegurado */
                                /***************************************************/
                                IF fonos_row.tip_ser != DBAPER.BUSCA_PARAMETRO('ODONTOLOGIA',FONOS_ROW.COMPANIA) THEN
                                ERROR1 := Paq_Matriz_Validaciones.Validar_Plan_Afiliado(fonos_row.PLAN,
                                                                                        fonos_row.tip_ser,
                                                                                        fonos_row.tip_rec,
                                                                                        FONOS_ROW.AFILIADO);

                                  Else
                                        DBMS_OUTPUT.PUT_LINE('VALIDAR_PLAN_AFILIADO_CAT:');
                                 CAT_PLAN_ODON :=   VALIDAR_PLAN_AFILIADO_CAT(fonos_row.PLAN,
                                                                               fonos_row.tip_ser,
                                                                               fonos_row.tip_rec,
                                                                               FONOS_ROW.AFILIADO,
                                                                               v_categoria,
                                                                               v_proveedor,
                                                                               FONOS_ROW.COMPANIA);


                                  IF NOT(CAT_PLAN_ODON) AND   (not VALIDA_RECLAMANTE(FONOS_ROW.AFILIADO)) THEN

                                    --
                                    ERROR1 := FALSE;
                                    --


                                   ELSIF (NVL(V_SIMULTANEO,'N') = 'S' OR fonos_row.PLAN = DBAPER.BUSCA_PARAMETRO('PLAN_BASICO',FONOS_ROW.COMPANIA)) THEN
                                     --
                                    ERROR1 := TRUE;
                                    --


                                  END IF;


                                  END IF;
                                -- DBMS_OUTPUT.PUT_LINE('Paq_Matriz_Validaciones.Validar_Plan_Afiliado 2 ');
                                IF ERROR1 THEN
                                  /***************************************************/
                                  /*    Validar coberturas mutuamente excluyente     */
                                  /***************************************************/
                                  ERROR := Paq_Matriz_Validaciones.Valida_Cob_Excluyente(TRUE,
                                                                                         VAR_ESTATUS_CAN,
                                                                                         VAR_TIP_A_USO,
                                                                                         COD_ASE,
                                                                                         COD_DEP,
                                                                                         FONOS_ROW.TIP_SER,
                                                                                         FONOS_ROW.TIP_COB,
                                                                                         FONOS_ROW.COBERTURA,
                                                                                         FECHA_DIA,
                                                                                         VAR_FEC_INI,
                                                                                         FONOS_ROW.FEC_ING,
                                                                                         PLA_STC_ROW.FRECUENCIA,
                                                                                         PLA_STC_ROW.UNI_TIE_F,
                                                                                         FONOS_ROW.PLAN);
                                  IF ERROR IS NULL THEN
                                    /***************************************************/
                                    /*    Validar Beneficio Maximo por Familia         */
                                    /***************************************************/
                                    ERROR1 := Paq_Matriz_Validaciones.Validar_Beneficio_Max(FONOS_ROW.COMPANIA,
                                                                                            FONOS_ROW.RAMO,
                                                                                            FONOS_ROW.SECUENCIAL,
                                                                                            FONOS_ROW.PLAN,
                                                                                            COD_ASE,
                                                                                            FECHA_DIA,
                                                                                            VAR_FEC_INI,
                                                                                            FONOS_ROW.FEC_ING,
                                                                                            FONOS_ROW.MON_PAG,
                                                                                            NULL);
                                    IF NOT (ERROR1) THEN
                                      /* --------------------------------------------- */
                                      /* Valida que el Monto Maximo digitado no exceda */
                                      /* el especificado en la Cobertura, solo para farmacias. */
                                      /* --------------------------------------------- */
                                      IF (FONOS_ROW.MON_REC_AFI IS NOT NULL AND
                                         FONOS_ROW.MON_REC_AFI <> 0) AND
                                         (PLA_STC_ROW.MON_MAX IS NOT NULL AND
                                         PLA_STC_ROW.MON_MAX <> 0) THEN
                                        IF (NVL(DSP_MON_PAG_ACUM, 0) +
                                           FONOS_ROW.MON_PAG) <
                                           PLA_STC_ROW.MON_MAX THEN
                                          VAR_CODE := 0;
                                        ELSE
                                          FONOS_ROW.MON_REC_AFI := PLA_STC_ROW.MON_MAX - DSP_MON_PAG_ACUM;
                                          VAR_CODE              := 2;
                                        END IF;
                                      ELSE
                                        VAR_CODE := 0;
                                      END IF;
                                    ELSE
                                      VAR_CODE := 2;
                                    END IF;
                                  ELSE
                                    var_code := 2;
                                  END IF;
                                ELSE
                                  var_code := 2;
                                END IF;
                              ELSE
                                var_code := 2;
                              END IF;
                            ELSE
                              -- del plan tipo de cobertura paralelo
                              var_code := 2;
                            END IF;
                          ELSE
                            var_code := 2;
                          END IF;
                        ELSE
                          var_code := 2;
                        END IF;
                      ELSE
                        var_code := 2;
                      END IF;
                    ELSE
                      var_code := 2;
                    END IF;
                  ELSE
                    var_code := 2;
                  END IF;
                ELSE
                  var_code := 2;
                END IF;
              ELSE
                var_code := 2;
              END IF;
            ELSE
              var_code := 3;
            END IF;
          ELSE
            var_code := 1;
          END IF;
        END IF;
      ELSE
        var_code := 1;
      END IF;

      --if nvl(v_internacional,'N') <> 'S' then --<84770> jdeveaux 10feb2016
      -- Victor Acevedo / TECHNOCONS.
      IF VAR_CODE = 0 THEN
        -- Para verificar si no hay ningun error
        -- VALIDAR_COBERTURA: Funcion para controlar la cobertura 2836 ------------------------------
        -- * Esta cobertura solo estara disponible en horario de 6:00 pm a 6:00 am
        -- * Las clinicas paquetes no deben reclamar por esta cobertura
        -- * Los medicos categoria A+ (Platinum) estan excepto de estas validaciones
        -- * Las excepciones deben poder ser manejadas por un superusuario
        -- * Para que el medico pueda reclamar el servicio el asegurado debe tener
        --   una reclamacion del mismo servicio (EMERGENCIA) por lo menos de 72 horas de antelacion.
        ---------------------------------------------------------------------------------------------
        /*
              IF FONOS_ROW.COBERTURA = 2836 THEN
                IF SUBSTR(VALIDAR_COBERTURA(vUSUARIO, FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO, FONOS_ROW.TIP_SER, 2836, SYSDATE, COD_DEP, COD_ASE), 1, 1) != '0' THEN
                   VAR_CODE := 2;
                END IF;
             END IF;
             -- Validar cobertura 2836
        */
        IF FONOS_ROW.TIP_SER <> 3 THEN
          -- SERVICIO DE EMERGENCIA
          -- Suspencion por Suplantacion (Fraude)
          mFRAUDE := 'N';

          -- para verificar si el afiliado tiene una marca de suspencion del servicio de salud
          OPEN C_FRAUDE;
          FETCH C_FRAUDE
            INTO mFRAUDE;
          CLOSE C_FRAUDE;

          IF mFRAUDE = 'S' THEN
            VAR_CODE := 2; -- VAR_CODE := 2;
          END IF;
          -- Fraude
        END IF;

      END IF; -- IF VAR_CODE <> 0 THEN

      --
      --<JDEVEAUX 18MAY2016>
      --Se restauran nuevamente los valores de la poliza voluntaria antes de salir de VALIDATECOBERTURA
      IF V_SEC_ORI IS NOT NULL THEN
        FONOS_ROW.PLAN       := V_PLAN_ORI;
        FONOS_ROW.COMPANIA   := V_COMPANIA_ORI;
        FONOS_ROW.RAMO       := V_RAMO_ORI;
        FONOS_ROW.SECUENCIAL := V_SEC_ORI;
      END IF;
      --</jdeveaux>

      --Miguel Carrion 04/11/2022
       IF V_COD_ERROR IS NOT NULL THEN
        VAR_CODE := V_COD_ERROR;
      END IF;

      -- Mirex
      IF FONOS_ROW.PLAN = 619 THEN
        IF V_DEDUCIBLE_MIREX < 0 THEN
          V_DEDUCIBLE_MIREX := 0;
        END IF;

        IF V_DEDUCIBLE_MIREX >= FONOS_ROW.MON_PAG THEN
          FONOS_ROW.MON_DED := FONOS_ROW.MON_PAG;
          FONOS_ROW.MON_PAG := 0;
        ELSE
          FONOS_ROW.MON_PAG := (FONOS_ROW.MON_PAG - V_DEDUCIBLE_MIREX);
          FONOS_ROW.MON_DED := V_DEDUCIBLE_MIREX;
        END IF;
      ELSE
        -- Si es otro plan distinto de mirex
        IF V_DEDUCIBLE_MIREX < 0 THEN
          V_DEDUCIBLE_MIREX := 0;
        END IF;

        IF V_DEDUCIBLE_MIREX >= FONOS_ROW.MON_PAG THEN
          FONOS_ROW.MON_DED := FONOS_ROW.MON_PAG;
          FONOS_ROW.MON_PAG := 0;
        ELSE
          FONOS_ROW.MON_PAG := (FONOS_ROW.MON_PAG - V_DEDUCIBLE_MIREX);
          FONOS_ROW.MON_DED := V_DEDUCIBLE_MIREX;
        END IF;

      END IF;
      ------ mirex

      FONOS_ROW.MON_PAG   := ROUND(FONOS_ROW.MON_PAG, 2);
      NO_M_COB_ROW.LIMITE := ROUND(NO_M_COB_ROW.LIMITE, 2);
      FONOS_ROW.POR_COA   := ROUND(POR_COA, 2);
      FONOS_ROW.MON_DED   := ROUND(FONOS_ROW.MON_DED, 2);

      IF VMESSAGE IS NOT NULL --- TIENE EXCESO POR GRUPO
       THEN
        UPDATE INFOX_SESSION
           SET CODE         = VAR_CODE,
               TIP_SER      = FONOS_ROW.TIP_SER,
               TIP_COB      = FONOS_ROW.TIP_COB,
               R_TIP_COB    = FONOS_ROW.TIP_COB,
               MON_REC      = FONOS_ROW.MON_PAG, --NO_M_COB_ROW.LIMITE,
               MON_PAG      = V_MONPAG_DEVUELVE_FUNCION,
               POR_COA      = FONOS_ROW.POR_COA,
               DES_COB      = COB_SAL_ROW.DESCRIPCION,
               MON_REC_AFI  = FONOS_ROW.MON_REC_AFI,
               COBERTURA    = FONOS_ROW.COBERTURA,
               MON_DED      = FONOS_ROW.MON_DED,
               COBERTURASTR = P_INSTR1
         WHERE CURRENT OF A;
        CLOSE A;
        --
        P_OUTSTR1 := LTRIM(TO_CHAR(FONOS_ROW.MON_PAG, '999999990.00'));
        P_OUTSTR2 := LTRIM(TO_CHAR(FONOS_ROW.MON_DED, '999999990.00'));
        P_OUTNUM1 := VAR_CODE;
        --
      ELSE

        --
        UPDATE INFOX_SESSION
           SET CODE         = VAR_CODE,
               TIP_SER      = FONOS_ROW.TIP_SER,
               TIP_COB      = FONOS_ROW.TIP_COB,
               R_TIP_COB    = FONOS_ROW.TIP_COB,
               MON_REC      = NO_M_COB_ROW.LIMITE,
               MON_PAG      = FONOS_ROW.MON_PAG,
               POR_COA      = FONOS_ROW.POR_COA,
               DES_COB      = COB_SAL_ROW.DESCRIPCION,
               MON_REC_AFI  = FONOS_ROW.MON_REC_AFI,
               COBERTURA    = FONOS_ROW.COBERTURA,
               MON_DED      = FONOS_ROW.MON_DED,
               COBERTURASTR = P_INSTR1
         WHERE CURRENT OF A;
        CLOSE A;
        --
        P_OUTSTR1 := LTRIM(TO_CHAR(FONOS_ROW.MON_PAG, '999999990.00'));
        P_OUTSTR2 := LTRIM(TO_CHAR(FONOS_ROW.MON_DED, '999999990.00'));
        P_OUTNUM1 := VAR_CODE;
        --
      END IF;

    END;
  END;

  --
  -- procedure inserta una cobertura en la reclamacion abierta por open reclamacion --
  -- 0->ok 1-> error --

  PROCEDURE P_INSERTCOBERTURA(p_name       IN VARCHAR2,
                              p_numsession IN NUMBER,
                              p_instr1     IN VARCHAR2,
                              p_instr2     IN VARCHAR2,
                              p_innum1     IN NUMBER,
                              p_innum2     IN NUMBER,
                              p_outstr1    OUT VARCHAR2,
                              p_outstr2    OUT VARCHAR2,
                              p_outnum1    OUT NUMBER,
                              p_outnum2    OUT NUMBER) IS
  BEGIN
    /* @%  Agregar Cobertura a Reclamacion */
    /* Nombre de la Funcion :  Agregar Cobertura a Reclamacion   */
    /* Descripcion : Graba en la tabla REC_C_SAL  un registro con un numero de    */
    /*               reclamacion */
    DECLARE
      FONOS_ROW      INFOX_SESSION%ROWTYPE;
      FECHA_DIA      DATE;
      VAR_CODE       NUMBER(2) := 1;
      VAR_RECLAMANTE NUMBER(14);
      VAR_TIP_REC    VARCHAR2(10);
      VAR_TIP_SER    NUMBER(2);
      VAR_TIP_COB    NUMBER(3);
      VAR_COBERTURA  NUMBER(5);
      VAR_MON_REC    NUMBER(11, 2);
      VAR_FEC_SER    DATE;
      VAR_ESTATUS    NUMBER(3);
      VAR_SECUENCIA  NUMBER(7);
      VAR_MON_PAG    NUMBER(11, 2);
      VAR_MON_DED    NUMBER(11, 2);
      VAR_POR_COA    NUMBER(11, 2);
      VAR_PLAN       NUMBER(3);
      V_PARAM        TPARAGEN.VALPARAM%TYPE := F_OBTEN_PARAMETRO_SEUS('PLA_SAL_INT');
      V_MIREX        NUMBER := TO_NUMBER(DBAPER.BUSCA_PARAMETRO('PLAN_MIREX',FONOS_ROW.COMPANIA));
      V_GRUPO        VARCHAR2(5);
      V_MONTO_REC    NUMBER(11,2);

      CURSOR A IS
        SELECT FEC_SER, ESTATUS, PLAN
          FROM RECLAMACION
         WHERE ANO = FONOS_ROW.ANO_REC
           AND COMPANIA = FONOS_ROW.COMPANIA
           AND RAMO = FONOS_ROW.RAMO
           AND SECUENCIAL = FONOS_ROW.SEC_REC;
      --
      CURSOR B IS
        SELECT NVL(MAX(SECUENCIA), 0) + 1
          FROM RECLAMACION_COBERTURA_SALUD
         WHERE ANO = FONOS_ROW.ANO_REC
           AND COMPANIA = FONOS_ROW.COMPANIA
           AND RAMO = FONOS_ROW.RAMO
           AND SECUENCIAL = FONOS_ROW.SEC_REC;
      --
      CURSOR C IS
        SELECT TIP_REC,
               AFILIADO,
               TIP_SER,
               TIP_COB,
               COBERTURA,
               ANO_REC,
               COMPANIA,
               RAMO,
               SEC_REC,
               MON_REC,
               MON_PAG,
               MON_DED,
               POR_COA
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION;
    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      --
      FECHA_DIA := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      OPEN C;
      FETCH C
        INTO VAR_TIP_REC,
             VAR_RECLAMANTE,
             VAR_TIP_SER,
             VAR_TIP_COB,
             VAR_COBERTURA,
             FONOS_ROW.ANO_REC,
             FONOS_ROW.COMPANIA,
             FONOS_ROW.RAMO,
             FONOS_ROW.SEC_REC,
             VAR_MON_REC,
             VAR_MON_PAG,
             VAR_MON_DED,
             VAR_POR_COA;
      IF C%FOUND THEN
        OPEN A;
        FETCH A
          INTO VAR_FEC_SER, VAR_ESTATUS, var_plan; --<HUMANO TPA> JDEVEAUX  se agrego el var_plan;
        IF A%FOUND THEN
          OPEN B;
          FETCH B
            INTO VAR_SECUENCIA;
          CLOSE B;
          --manejo error constraint cobertura , manejado por trigger en tabla rec_c_sal--
          BEGIN
            IF VMESSAGE IS NOT NULL THEN
              -- AGREGADO PARA CUANDO EL MONTO NO CUBIERTO SEA POR AGOTAMIENTO DEL GRUPO.
              VAR_MON_DED := VAR_MON_REC - VAR_MON_PAG;
            END IF;
            --
                          
            --Para realizar calculo del monto reclamado por la N frecuencia Miguel A. Carrion 05/05/2022
            IF p_innum1 IS NOT NULL THEN

              V_MONTO_REC := VAR_MON_REC * p_innum1;
              VAR_MON_DED := VAR_MON_DED * p_innum1;
              VAR_MON_PAG := VAR_MON_PAG * p_innum1;

            END IF;

            INSERT INTO REC_C_SAL
              (ANO,
               COMPANIA,
               RAMO,
               SECUENCIAL,
               SECUENCIA,
               SERVICIO,
               TIP_COB,
               COBERTURA,
               FEC_SER,
               FRECUENCIA,
               MON_REC,
               RESERVA,
               ESTATUS,
               LIM_AFI,
               MON_PAG,
               POR_COA,
               TIP_REC,
               RECLAMANTE,
               MON_COASEG,
               EXCEDENTE_COPAGO)
            VALUES
              (FONOS_ROW.ANO_REC,
               FONOS_ROW.COMPANIA,
               FONOS_ROW.RAMO,
               FONOS_ROW.SEC_REC,
               VAR_SECUENCIA,
               VAR_TIP_SER,
               VAR_TIP_COB,
               VAR_COBERTURA,
               VAR_FEC_SER,
               nvl(p_innum1,1), --Se agrego el parametro para inserta las N frecuencia que se le envie en caso de que venga Null inserta frecuencia 1 Miguel A. Carrion 08/12/2021
               nvl(V_MONTO_REC,VAR_MON_REC),
               nvl(V_MONTO_REC,VAR_MON_REC),
               VAR_ESTATUS,
               VAR_MON_REC,
               VAR_MON_PAG,
               VAR_POR_COA,
               VAR_TIP_REC,
               VAR_RECLAMANTE,
               VAR_MON_DED,
               0);

            --ACUMULAR CAMPO TOT_MON_DED--
            UPDATE INFOX_SESSION
               SET TOT_MON_DED = NVL(TOT_MON_DED, 0) + NVL(VAR_MON_DED, 0)
             WHERE NUMSESSION = P_NUMSESSION;

            --<84770> jdeveaux --> Se inserta en REC_c_sal_sc
            IF FONOS_ROW.RAMO = 93 AND
               INSTR(V_PARAM, ',' || VAR_PLAN || ',') = 0 AND
               VMESSAGE IS NULL THEN
              -- PARA QUE NO ENTRE CUANDO SEA LIMITADO POR GRUPO.
              --
              INSERT INTO DBAPER.REC_C_SAL_SC
                (ANO,
                 COMPANIA,
                 RAMO,
                 SECUENCIAL,
                 SECUENCIA,
                 COBERTURA,
                 TASA,
                 DEDUCIBLE)
              VALUES
                (FONOS_ROW.ANO_REC,
                 FONOS_ROW.COMPANIA,
                 FONOS_ROW.RAMO,
                 FONOS_ROW.SEC_REC,
                 VAR_SECUENCIA,
                 VAR_COBERTURA,
                 f_tasa('002', trunc(sysdate), 'C'),
                 var_mon_ded);
            end if;
            --</84770>

              -- Pregunta para inserta el subgrupo por el cual se realizo la autorizacion de alto Costo  Miguel A. Carrion 10/09/2021
                IF VAR_TIP_SER = TO_NUMBER(DBAPER.BUSCA_PARAMETRO('TIP_SERV_CONS_MEDI_0',FONOS_ROW.COMPANIA)) 
                OR VAR_TIP_SER =  TO_NUMBER(PKG_GENERAL.F_OBTEN_PARAMETRO_SEUS('SERVICIO_RENAL',96))  then
                                                           


                  INSERT INTO RECLAMACION_TIPO_COBERTURA
                    (ANO, COMPANIA, RAMO, SECUENCIAL, TIP_COB, FEC_SER, DIAGNOSTICO)
                  VALUES
                    (FONOS_ROW.ANO_REC,
                     FONOS_ROW.COMPANIA,
                     FONOS_ROW.RAMO,
                     FONOS_ROW.SEC_REC,
                     VAR_TIP_COB,
                     VAR_FEC_SER,
                     DBAPER.BUSCA_PARAMETRO('DIAGNOSTICO',FONOS_ROW.COMPANIA));

                END IF;
                ---FIN  Miguel A. Carrion 10/09/202


            ------------------------------------------------------------------------------------
            -- Agregado por Leonardo para que cuando la variable V_MIREX sea igual al plan    --
            -- asigne el valor AML a la variable de grupo, de lo contrario se queda como GEN  --
            ------------------------------------------------------------------------------------
            V_GRUPO := 'GEN';
            IF TO_NUMBER(V_MIREX) = TO_NUMBER(VAR_PLAN) THEN
              V_GRUPO := DBAPER.VAL_GRUPO_X_TIP_COB_GRUPO(VAR_PLAN,
                                                          VAR_TIP_SER,
                                                          VAR_TIP_COB);
            END IF;
            --<84770> jdeveaux --> Se inserta en RECLAMACION_GRUPO_COBERTURA
            --
            IF FONOS_ROW.RAMO = 93 AND
               INSTR(V_PARAM, ',' || VAR_PLAN || ',') = 0 THEN
              DECLARE
                vDUMMY VARCHAR2(1);
                --
                CURSOR C_RGC IS
                  SELECT '1'
                    FROM DBAPER.RECLAMACION_GRUPO_COBERTURA
                   WHERE ANO = FONOS_ROW.ANO_REC
                     AND COMPANIA = FONOS_ROW.COMPANIA
                     AND RAMO = FONOS_ROW.RAMO
                     AND SECUENCIAL = FONOS_ROW.SEC_REC
                     AND GRUPO_COBERTURA = V_GRUPO;
              BEGIN
                OPEN C_RGC;
                FETCH C_RGC
                  INTO vDUMMY; -- Estabilizacion Salud Internacional. No se dupliquen los grupos al registrar varias coberturas.
                IF C_RGC%NOTFOUND THEN
                  INSERT INTO DBAPER.RECLAMACION_GRUPO_COBERTURA
                    (ANO,
                     COMPANIA,
                     RAMO,
                     SECUENCIAL,
                     GRUPO_COBERTURA,
                     FEC_SER,
                     USU_U_AC,
                     FEC_U_AC)
                  VALUES
                    (FONOS_ROW.ANO_REC,
                     FONOS_ROW.COMPANIA,
                     FONOS_ROW.RAMO,
                     FONOS_ROW.SEC_REC,
                     V_GRUPO,
                     FECHA_DIA,
                     USER,
                     SYSDATE);
                END IF;
                CLOSE C_RGC;
              END;
            end if;
            --</84770>
            VAR_CODE := 0;
          /*EXCEPTION
            WHEN others THEN
              VAR_CODE := 1;*/
          END;
        ELSE
          VAR_CODE := 1;
        END IF;
        CLOSE A;
      END IF;
      CLOSE C;
      P_OUTNUM1 := VAR_CODE;
    END;
  END;
  --
  -- procedure crea un nuevo registro en la tabla de llamadas y devuelve el numero de registro --
  -- 0->ok 1-> error --
  PROCEDURE P_OPENSESSION(p_name       IN VARCHAR2,
                          p_numsession IN NUMBER,
                          p_instr1     IN VARCHAR2,
                          p_instr2     IN VARCHAR2,
                          p_innum1     IN NUMBER,
                          p_innum2     IN NUMBER,
                          p_outstr1    OUT VARCHAR2,
                          p_outstr2    OUT VARCHAR2,
                          p_outnum1    OUT NUMBER,
                          p_outnum2    OUT NUMBER) IS
  BEGIN
    DECLARE
      INFOX_SESSION_ROW INFOX_SESSION%ROWTYPE;
      VAR_CODE          NUMBER(1) := 1;
      VAR_MAQUINA       VARCHAR2(30);
      --
      CURSOR C_SEQSESSION IS
        SELECT SEQSESSION.NEXTVAL FROM SYS.DUAL;
      --
      CURSOR C_MAQUINA IS
        SELECT SUBSTR(MACHINE, 1, 30)
          FROM V$SESSION
         WHERE USERNAME = USER
           AND AUDSID = SYS_CONTEXT('USERENV', 'SESSIONID');
    BEGIN
      -- este procedure no es necesario en el metodo de openSession pero en caso de incluir regla de negocios que necesite el usuario no quedara fuera. Peter Rosario 13/07/2013
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

      OPEN C_SEQSESSION;
      FETCH C_SEQSESSION
        INTO INFOX_SESSION_ROW.NUMSESSION;
      IF C_SEQSESSION%FOUND THEN
        OPEN C_MAQUINA;
        FETCH C_MAQUINA
          INTO VAR_MAQUINA;
        CLOSE C_MAQUINA;
        INSERT INTO INFOX_SESSION
          (NUMSESSION, INICIO, MAQUINA)
        VALUES
          (INFOX_SESSION_ROW.NUMSESSION, SYSDATE, VAR_MAQUINA);
        VAR_CODE := 0;
      END IF;
      CLOSE C_SEQSESSION;
      P_OUTNUM1 := VAR_CODE;
      P_OUTNUM2 := INFOX_SESSION_ROW.NUMSESSION;
    END;
  END;
  --
  -- procedure completa todos los campos que faltan de la tabla de llamadas --
  --sin el afiliado esta en "" no pone el campo de ciudad, pues no se ingreso un afiliado valido--
  -- 0->ok 1-> error --
  PROCEDURE P_CLOSESESSION(p_name       IN VARCHAR2,
                           p_numsession IN NUMBER,
                           p_instr1     IN VARCHAR2,
                           p_instr2     IN VARCHAR2,
                           p_innum1     IN NUMBER,
                           p_innum2     IN NUMBER,
                           p_outstr1    OUT VARCHAR2,
                           p_outstr2    OUT VARCHAR2,
                           p_outnum1    OUT NUMBER,
                           p_outnum2    OUT NUMBER) IS
  BEGIN
    DECLARE
      INFOX_SESSION_ROW INFOX_SESSION%ROWTYPE;
      VAR_CODE          NUMBER(1) := 1;
      CURSOR C_SESSION IS
        SELECT NUMSESSION, INICIO
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION
           FOR UPDATE;

    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

      OPEN C_SESSION;
      FETCH C_SESSION
        INTO INFOX_SESSION_ROW.NUMSESSION, INFOX_SESSION_ROW.INICIO;
      IF C_SESSION%FOUND THEN
        UPDATE INFOX_SESSION
           SET TERMINO  = SYSDATE,
               DURACION = TO_NUMBER(TO_CHAR(SYSDATE, 'HHMISS')) -
                          TO_NUMBER(TO_CHAR(INFOX_SESSION_ROW.INICIO,
                                            'HHMISS'))
         WHERE CURRENT OF C_SESSION;
        VAR_CODE := 0;
      END IF;
      CLOSE C_SESSION;
      P_OUTNUM1 := VAR_CODE;
    END;
  END;
  --
  -- procedure abre una reclamacion temporal --
  -- 0->ok 1-> error --
  PROCEDURE P_OPENRECLAMACION(p_name       IN VARCHAR2,
                              p_numsession IN NUMBER,
                              p_instr1     IN VARCHAR2,
                              p_instr2     IN VARCHAR2,
                              p_innum1     IN NUMBER,
                              p_innum2     IN NUMBER,
                              p_outstr1    OUT VARCHAR2,
                              p_outstr2    OUT VARCHAR2,
                              p_outnum1    OUT NUMBER,
                              p_outnum2    OUT NUMBER) IS
  BEGIN
    /* @% Agregar Reclamacion */
    /* Nombre de la Funcion :  Agregar Reclamacion   */
    /* Descripcion : Graba en la tabla RECLAMACION  un registro con un numero de  */
    /* reclamacion   */
    DECLARE
      FECHA_DIA       DATE;
      VAR_CODE        NUMBER(2) := 1;
      SEC_RECLAMACION NUMBER(9);
      VAR_ANO_REC     VARCHAR2(4);
      VAR_RECLAMANTE  NUMBER(14);
      VAR_ASEGURADO   VARCHAR2(15);
      VAR_DEPENDIENTE VARCHAR2(3);
      VAR_COMPANIA    NUMBER(2);
      VAR_RAMO        NUMBER(2);
      VAR_SECUENCIAL  NUMBER(7);
      VAR_PLAN        NUMBER(3);
      VAR_TIP_REC     VARCHAR2(10);
      VAR_TIP_SER     NUMBER(2);
      VAR_TIP_A_USO   VARCHAR2(10);
      VAR_ASE_USO     NUMBER(11);
      VAR_DEP_USO     NUMBER(3);
      VAR_MED_TRA     NUMBER(7);
      VAR_RIE_LAB     VARCHAR2(1);
      VAR_NUM_PLA     VARCHAR2(20);
      VAR_TIP_COB     NUMBER(3); -- MIREX

      CURSOR I(cCDRAMO NUMBER) IS
        SELECT 'L' LOC_PRO, 'P' TIP_PRO, '001' CDMONEDA
          FROM RAMO
         WHERE CODIGO = cCDRAMO
           AND TIP_RAM = 4; -- Salud Internacional
      --
      I_ROW I%ROWTYPE;
      --
      CURSOR B IS
        SELECT TO_CHAR(SYSDATE, 'YYYY') FROM SYS.DUAL;

      CURSOR C IS
        SELECT AFILIADO,
               ASEGURADO,
               DEPENDIENTE,
               COMPANIA,
               RAMO,
               SECUENCIAL,
               PLAN,
               TIP_REC,
               TIP_SER,
               MED_TRA,
               RIE_LAB,
               ASE_CARNET, -- Indica el Numero de Plastico digitado. GMa?on 15/09/2010
               TIP_COB -- MIREX
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION
           FOR UPDATE;

    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

      FECHA_DIA := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      OPEN B;
      FETCH B
        INTO VAR_ANO_REC;
      CLOSE B;
      --
      OPEN C;
      FETCH C
        INTO VAR_RECLAMANTE,
             VAR_ASEGURADO,
             VAR_DEPENDIENTE,
             VAR_COMPANIA,
             VAR_RAMO,
             VAR_SECUENCIAL,
             VAR_PLAN,
             VAR_TIP_REC,
             VAR_TIP_SER,
             VAR_MED_TRA,
             VAR_RIE_LAB,
             VAR_NUM_PLA,
             VAR_TIP_COB; --MIREX
      IF C%FOUND THEN

        SEC_RECLAMACION := fnc_adm_contador('RECLAMACION',
                                            VAR_ANO_REC,
                                            VAR_COMPANIA,
                                            VAR_RAMO);
        --
        VAR_ASE_USO := TO_NUMBER(VAR_ASEGURADO);
        VAR_DEP_USO := TO_NUMBER(VAR_DEPENDIENTE);
        --
        IF NVL(VAR_DEP_USO, 0) > 0 THEN
          VAR_TIP_A_USO := 'DEPENDIENT';
        ELSE
          VAR_TIP_A_USO := 'ASEGURADO';
          VAR_DEP_USO   := NULL;
          IF PKG_SALUDINT.F_RAMO_SALUD_INT(VAR_RAMO) THEN
            -- Incluir 0 para asegurados y poder relacionar con la vista ASE_DEP01_V [Enfoco | GM]
            VAR_DEP_USO := 0;
          END IF;
        END IF;
        --
        OPEN I(VAR_RAMO);
        FETCH I
          INTO I_ROW.LOC_PRO, I_ROW.TIP_PRO, I_ROW.CDMONEDA;
        CLOSE I;

        INSERT INTO RECLAMACION
          (ANO,
           COMPANIA,
           RAMO,
           SECUENCIAL,
           SEC_POL,
           PLAN,
           USU_ING,
           FEC_APE,
           FEC_TRA,
           FEC_SER,
           TIP_REC,
           RECLAMANTE,
           TIP_A_USO,
           ASE_USO,
           TIP_SER,
           ESTATUS,
           DEP_USO,
           REFERENCIA,
           RIE_LAB,
           NUM_PLA,
           CANAL,
           LOC_PRO,
           TIP_PRO,
           CDMONEDA)
        VALUES
          (VAR_ANO_REC,
           VAR_COMPANIA,
           VAR_RAMO,
           SEC_RECLAMACION,
           VAR_SECUENCIAL,
           VAR_PLAN,
           vUsuario,
           SYSDATE, -- FECHA_DIA, Trunc (No tenia la Hora) VA
           SYSDATE,
           FECHA_DIA,
           VAR_TIP_REC,
           VAR_RECLAMANTE,
           VAR_TIP_A_USO,
           VAR_ASE_USO,
           VAR_TIP_SER,
            DBAPER.f_busca_usu_Est_Inic_canales(user), --Se agrego funcion para obtener los estatus iniciar   del reclamos
                                                         --- JOSE DE LEON @ENFOCO
           --DECODE(vUsuario, 'KIOSKO', 179, 83), -- AGREGADO POR LEONARDO PROYECTO KIOSKO
           VAR_DEP_USO,
           VAR_MED_TRA,
           VAR_RIE_LAB,
           VAR_NUM_PLA,
           vCANAL,
           I_ROW.LOC_PRO,
           I_ROW.TIP_PRO,
           I_ROW.CDMONEDA);

        /*----------------------------------------------------------------------
        --  Victor Acevedo
        --  Proyecto Prescriptor 01-Ago-2016
        --  Insertando en la tabla de prescriptores
        */ ----------------------------------------------------------------------
        IF nvl(p_innum1, 0) > 0 THEN
          INSERT INTO RECLAMACION_PRESCRIPTOR
            (ANO,
             COMPANIA,
             RAMO,
             SECUENCIAL,
             COD_MEDICO,
             CREADO_POR,
             CREADO_EN)
          VALUES
            (VAR_ANO_REC,
             VAR_COMPANIA,
             VAR_RAMO,
             SEC_RECLAMACION,
             p_innum1,
             vUsuario,
             SYSDATE);
        END IF;

        VAR_CODE := 0;

        UPDATE INFOX_SESSION
           SET CODE        = VAR_CODE,
               ANO_REC     = VAR_ANO_REC,
               SEC_REC     = SEC_RECLAMACION,
               RECLAMACION = LTRIM(TO_CHAR(SEC_RECLAMACION))
         WHERE CURRENT OF C;

      END IF;
      CLOSE C;
      P_OUTNUM1 := VAR_CODE;
      P_OUTSTR1 := SEC_RECLAMACION;
      P_OUTSTR2 := VAR_RAMO;
    END;
  END;
  --
  -- procedure hace que la reclamacion recien aperturada sea definitiva --
  -- 0->ok 1-> error --
  PROCEDURE P_CLOSERECLAMACION(p_name       IN VARCHAR2,
                               p_numsession IN NUMBER,
                               p_instr1     IN VARCHAR2,
                               p_instr2     IN VARCHAR2,
                               p_innum1     IN NUMBER,
                               p_innum2     IN NUMBER,
                               p_outstr1    OUT VARCHAR2,
                               p_outstr2    OUT VARCHAR2,
                               p_outnum1    OUT NUMBER,
                               p_outnum2    OUT NUMBER) IS
  BEGIN
    /* Descripcion : Realmente no cambia ningun estatus, la reclamacion ya fue creada con estatus definitivo.*/
    /*               Retorno el total general a pagar por ars y por el asegurado*/
    DECLARE
      FECHA_DIA       DATE;
      VAR_CODE        NUMBER(2) := 1;
      ANO_REC         NUMBER(4);
      CIA_REC         NUMBER(2);
      RAM_REC         NUMBER(2);
      VAR_ESTATUS     NUMBER(3);
      VAR_MON_PAG     NUMBER(16, 2);
      VAR_MON_DED     NUMBER(16, 2);
      FONOS_ROW       INFOX_SESSION%ROWTYPE;
      V_ERROR_MESSAGE VARCHAR2(2000);

      CURSOR A IS
        SELECT SEC_REC, AFILIADO, TIP_REC, COMPANIA, RAMO, TOT_MON_DED
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION
           FOR UPDATE;

      CURSOR B IS
        SELECT ESTATUS
          FROM RECLAMACION
         WHERE ANO = ANO_REC
           AND COMPANIA = CIA_REC
           AND RAMO = RAM_REC
           AND SECUENCIAL = FONOS_ROW.SEC_REC
           AND TIP_REC = FONOS_ROW.TIP_REC
           AND RECLAMANTE = FONOS_ROW.AFILIADO;

      CURSOR C IS
        SELECT SUM(NVL(MON_PAG, 0)) --, SUM(NVL(MON_DED,0))
          FROM REC_C_SAL
         WHERE ANO = ANO_REC
           AND COMPANIA = CIA_REC
           AND RAMO = RAM_REC
           AND SECUENCIAL = FONOS_ROW.SEC_REC;
    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      FECHA_DIA := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      OPEN A;
      FETCH A
        INTO FONOS_ROW.SEC_REC,
             FONOS_ROW.AFILIADO,
             FONOS_ROW.TIP_REC,
             CIA_REC,
             RAM_REC,
             VAR_MON_DED;
      IF A%FOUND THEN
        ANO_REC := TO_NUMBER(SUBSTR(TO_CHAR(FECHA_DIA, 'DD/MM/YYYY'), 7, 4));





         Update RECLAMACION SET ESTATUS = F_OBTEN_PARAMETRO_SEUS('ESTATUS_FONO_WEB',CIA_REC)
         WHERE ANO = ANO_REC
           AND COMPANIA = CIA_REC
           AND RAMO = RAM_REC
           AND SECUENCIAL = FONOS_ROW.SEC_REC
           AND TIP_REC = FONOS_ROW.TIP_REC
           AND RECLAMANTE = FONOS_ROW.AFILIADO
           AND ESTATUS = F_OBTEN_PARAMETRO_SEUS('ESTATUS_TRANSITORIO',CIA_REC); --- EN EL CIERRE DE LA SESSION  BUSCAMOS EL RECLAMOS  PARA COLOCAR EL ESTATUS QUE LE CORRESPONDE AL IVR
                              ---Jose De Leon @Enfoco




        OPEN B;
        FETCH B
          INTO VAR_ESTATUS;
        IF B%FOUND AND VAR_ESTATUS IN (83, 179, 122) -- KIOSKO
         THEN
          OPEN C;
          FETCH C
            INTO VAR_MON_PAG; /*--, VAR_MON_DED;*/
          CLOSE C;
          VAR_CODE := 0;
        ELSE
          VAR_CODE := 1;
        END IF;
        UPDATE INFOX_SESSION SET CODE = VAR_CODE WHERE CURRENT OF A;
      END IF;
      CLOSE A;
      CLOSE B;

      P_OUTNUM1 := VAR_CODE;
      P_OUTSTR1 := ltrim(to_char(NVL(VAR_MON_PAG, 0), '999999990.00'));
      P_OUTSTR2 := ltrim(to_char(NVL(VAR_MON_DED, 0), '999999990.00'));

      -- PASA LAS RECLAMACIONES PARA SALUD CORE.
      IF RAM_REC = 93 THEN
        null;/*DBAPER.PAQ_SYNC_RECLAMACION.P_SYNC_REC_INF_SAL(ANO_REC,
                                                       CIA_REC,
                                                       RAM_REC,
                                                       FONOS_ROW.SEC_REC,
                                                       'INSERT',
                                                       V_ERROR_MESSAGE);*/
      END IF;

      -- Proceso para crear un Ingreso a partir de una Reclamacion dada
      BEGIN
        p_INGRESO_FROM_RECLAMAC(p_NUMSESSION);
      END;

    END;

  END;
  --
  -- procedure borra una reclamacion del afiliado y que no haya sifo procesada aun. --
  -- 0->ok 1-> error 2-> que ya no se puede borrar, ha sido procesada--
  PROCEDURE P_DELETERECLAMACION(p_name       IN VARCHAR2,
                                p_numsession IN NUMBER,
                                p_instr1     IN VARCHAR2,
                                p_instr2     IN VARCHAR2,
                                p_innum1     IN NUMBER,
                                p_innum2     IN NUMBER,
                                p_outstr1    OUT VARCHAR2,
                                p_outstr2    OUT VARCHAR2,
                                p_outnum1    OUT NUMBER,
                                p_outnum2    OUT NUMBER) IS
  BEGIN
    /* Descripcion : Cancela una Reclamacion cambiando su estatus en la tabla RECLAMACION */
    DECLARE
      FECHA_DIA   DATE;
      VAR_CODE    NUMBER(2) := 1;
      ANO_REC     NUMBER(4);
      CIA_REC     NUMBER(2);
      RAM_REC     NUMBER(2);
      VAR_ESTATUS NUMBER(3);
      cmb_estatus number(3) := 0;
      FONOS_ROW   INFOX_SESSION%ROWTYPE;

      CURSOR A IS
        SELECT SEC_REC, AFILIADO, TIP_REC, COMPANIA, RAMO
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION
           FOR UPDATE;

      CURSOR B IS
        SELECT ESTATUS
          FROM RECLAMACION
         WHERE ANO = ANO_REC
           AND COMPANIA = CIA_REC
           AND RAMO = RAM_REC
           AND SECUENCIAL = FONOS_ROW.SEC_REC
           AND TIP_REC = FONOS_ROW.TIP_REC
           AND RECLAMANTE = FONOS_ROW.AFILIADO
           FOR UPDATE;
    BEGIN

      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

      FECHA_DIA   := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      cmb_estatus := nvl(p_innum1, 0);
      IF (cmb_estatus <= 0) THEN
        cmb_estatus := 52;
      END IF;
      OPEN A;
      FETCH A
        INTO FONOS_ROW.SEC_REC,
             FONOS_ROW.AFILIADO,
             FONOS_ROW.TIP_REC,
             CIA_REC,
             RAM_REC;
      IF A%FOUND THEN
        ANO_REC := TO_NUMBER(SUBSTR(TO_CHAR(FECHA_DIA, 'DD/MM/YYYY'), 7, 4));
        OPEN B;
        FETCH B
          INTO VAR_ESTATUS;
        IF B%FOUND AND (VAR_ESTATUS = 83 OR VAR_ESTATUS = 52) THEN
          UPDATE RECLAMACION SET ESTATUS = cmb_estatus, motivo_estatus =  p_innum2 WHERE CURRENT OF B;
          VAR_CODE := 0;
          UPDATE REC_C_SAL
             SET ESTATUS = 57
           WHERE ANO = ANO_REC
             AND COMPANIA = CIA_REC
             AND RAMO = RAM_REC
             AND SECUENCIAL = FONOS_ROW.SEC_REC;

               /*Insert para registrar el comentario de cancelacion Miguel A. Carrion 19/03/2021*/
               Insert Into coment_reclamaciones(ANO, COMPANIA, RAMO, SECUENCIAL,
                                        USUARIO, FECHA, COMENT,  FECHA_CREO
                                       )Values
                                       (ANO_REC,CIA_REC,RAM_REC,FONOS_ROW.SEC_REC,
                                        vUsuario,FECHA_DIA,p_instr1,FECHA_DIA);

        ELSE
          VAR_CODE := 1;
        END IF;
        UPDATE INFOX_SESSION SET CODE = VAR_CODE WHERE CURRENT OF A;
      END IF;
      CLOSE A;
      CLOSE B;
      P_OUTNUM1 := VAR_CODE;
    END;
  END;

PROCEDURE P_DELETECOBERTURA (
    p_name         IN             VARCHAR2,
    p_numsession   IN             NUMBER,
    p_instr1       IN             VARCHAR2,
    p_instr2       IN             VARCHAR2,
    p_innum1       IN             NUMBER,
    p_innum2       IN             NUMBER,
    p_outstr1      OUT            VARCHAR2,
    p_outstr2      OUT            VARCHAR2,
    p_outnum1      OUT            NUMBER,
    p_outnum2      OUT            NUMBER
) IS
BEGIN

    DECLARE
        fecha_dia      DATE;
        var_code       NUMBER(2) := 99; -- Error desconocido (default)
        ano_rec        NUMBER(4);
        cia_rec        NUMBER(2);
        ram_rec        NUMBER(2);
        var_estatus    NUMBER(3);
        cmb_estatus    NUMBER(3) := 0;
        fonos_row      infox_session%rowtype;
        p_cobertura    NUMBER(8) := p_innum1;

        CURSOR c_sesion IS
        SELECT ano_rec, sec_rec, compania, ramo
        FROM infox_session
        WHERE numsession = p_numsession;

        CURSOR c_rec IS
        SELECT estatus
        FROM reclamacion
        WHERE ano = fonos_row.ano_rec
            AND compania = fonos_row.compania
            AND ramo = fonos_row.ramo
            AND secuencial = fonos_row.sec_rec;

        CURSOR c_cob IS
        SELECT estatus
        FROM rec_c_sal
        WHERE ano = fonos_row.ano_rec
            AND compania = fonos_row.compania
            AND ramo = fonos_row.ramo
            AND secuencial = fonos_row.sec_rec
            AND cobertura = p_cobertura;

    BEGIN

            -- Busca la sesi??n
        OPEN c_sesion;
        FETCH c_sesion INTO
            fonos_row.ano_rec,
            fonos_row.sec_rec,
            fonos_row.compania,
            fonos_row.ramo;

        IF c_sesion%found THEN
            -- Busca la reclamaci??n
            OPEN c_rec;
            FETCH c_rec INTO var_estatus;

            IF c_rec%found AND ( var_estatus = V_83 OR var_estatus = V_122 ) THEN
                -- Busca la cobertura
                OPEN c_cob;
                FETCH c_cob INTO var_estatus;

                IF c_cob%found AND ( var_estatus = V_83 OR var_estatus = V_56 ) THEN
                    -- Cancela la cobertura

          DELETE FROM rec_c_sal
                    WHERE
                        ano = fonos_row.ano_rec
                        AND compania = fonos_row.compania
                        AND ramo = fonos_row.ramo
                        AND secuencial = fonos_row.sec_rec
                        AND cobertura = p_cobertura;

    --                    DBMS_OUTPUT.put_line('RowCount: ' || SQL%ROWCOUNT);

                    var_code := 0; -- OK

                ELSE
                    var_code := 3; -- Cobertura inv?!lida

                END IF;

                CLOSE c_cob;

            ELSE
                var_code := 2; -- Reclamacion con estado invalido

            END IF;

            CLOSE c_rec;

        ELSE
            var_code := 1; -- No encontro la sesion

        END IF;

        CLOSE c_sesion;
      P_OUTNUM1 := VAR_CODE;
    --      DBMS_OUTPUT.put_line('Resultado: ' || P_OUTNUM1);
    END;
  END;
  --
  -- procedure Resumen de reclamaciones diarias aperturadas por fonosalud --
  -- 0-> valido 1-> invalido/no hay reclamos para este dia --
  PROCEDURE P_RESUMENRECLAMACION(p_name       IN VARCHAR2,
                                 p_numsession IN NUMBER,
                                 p_instr1     IN VARCHAR2,
                                 p_instr2     IN VARCHAR2,
                                 p_innum1     IN NUMBER,
                                 p_innum2     IN NUMBER,
                                 p_outstr1    OUT VARCHAR2,
                                 p_outstr2    OUT VARCHAR2,
                                 p_outnum1    OUT NUMBER,
                                 p_outnum2    OUT NUMBER) IS
  BEGIN
    /* @% Buscar Reclamacion */
    /* Descripcion : Busca datos de una reclamacion */
    DECLARE
      FONOS_ROW   INFOX_SESSION%ROWTYPE;
      REC_COB_ROW REC_C_SAL%ROWTYPE;
      VAR_CODE    NUMBER(1) := 1;
      FECHA_DIA   DATE;
      ANO_REC     NUMBER(4);
      CURSOR A IS
        SELECT ANO_REC,
               COMPANIA,
               RAMO,
               SEC_REC,
               TIP_REC,
               AFILIADO,
               SECUENCIAL,
               RECLAMACION
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION
           FOR UPDATE;

      CURSOR B IS
        SELECT SUM(B.MON_PAG)
          FROM RECLAMACION A, REC_C_SAL B
         WHERE A.ANO = ANO_REC
           AND A.COMPANIA = FONOS_ROW.COMPANIA
           AND A.RAMO = FONOS_ROW.RAMO
           AND A.SECUENCIAL = FONOS_ROW.SEC_REC
           AND A.TIP_REC = FONOS_ROW.TIP_REC
           AND A.RECLAMANTE = FONOS_ROW.AFILIADO
           AND TRUNC(A.FEC_APE) = TRUNC(FECHA_DIA)
           AND A.ESTATUS = (SELECT E.CODIGO
                              FROM ESTATUS E
                             WHERE E.CODIGO = A.ESTATUS
                               AND VAL_LOG = V_T)
           AND B.ANO = A.ANO
           AND B.COMPANIA = A.COMPANIA
           AND B.RAMO = A.RAMO
           AND B.SECUENCIAL = A.SECUENCIAL;

    BEGIN

      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

      FECHA_DIA := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      ANO_REC   := TO_NUMBER(SUBSTR(TO_CHAR(FECHA_DIA, 'DD/MM/YYYY'), 7, 4));
      OPEN A;
      FETCH A
        INTO FONOS_ROW.ANO_REC,
             FONOS_ROW.COMPANIA,
             FONOS_ROW.RAMO,
             FONOS_ROW.SEC_REC,
             FONOS_ROW.TIP_REC,
             FONOS_ROW.AFILIADO,
             FONOS_ROW.SECUENCIAL,
             FONOS_ROW.RECLAMACION;
      IF A%FOUND THEN
        OPEN B;
        FETCH B
          INTO REC_COB_ROW.MON_PAG;
        IF B%FOUND AND NVL(REC_COB_ROW.MON_PAG, 0) > 0 THEN
          UPDATE INFOX_SESSION SET CODE = 0 WHERE CURRENT OF A;
          VAR_CODE := 0;
        ELSE
          UPDATE INFOX_SESSION SET CODE = 1 WHERE CURRENT OF A;
          VAR_CODE := 1;
        END IF;
        CLOSE B;
      ELSE
        VAR_CODE := 2;
      END IF;
      CLOSE A;
      P_OUTSTR1 := ltrim(to_char(REC_COB_ROW.MON_PAG, '999999990.00'));
      P_OUTNUM1 := VAR_CODE;
    END;
  END;
  -- ******************************************************************** --
  PROCEDURE p_INGRESO_FROM_RECLAMAC(p_NUMSESSION IN NUMBER) IS
    -- Proceso para crear un Ingreso a partir de una Reclamacion dada
    -- Creado por Htorres para Enfoco - 28/07/2019
  BEGIN
    DECLARE
      FONOS_ROW           INFOX_SESSION%ROWTYPE;
      vSECUENCIA          NUMBER := 0;
      vCOB_ROW            REC_C_SAL%ROWTYPE;
      vNUM_INGRESO        NUMBER;
      vEST_REP_CONVERTIDA REP_HOS.ESTATUS%TYPE := 60;
      vSERVICIO_PARAM     VARCHAR2(256) := F_OBTEN_PARAMETRO_SEUS('ING_FROM_REC_TIP_SER');
      VAR_ANO             NUMBER(4) := TO_CHAR(SYSDATE, 'YYYY');

      CURSOR A IS
        SELECT ANO_REC, COMPANIA, RAMO, SEC_REC, TIP_SER
          FROM INFOX_SESSION
         WHERE NUMSESSION = p_NUMSESSION;

      CURSOR REC_C IS
        SELECT ANO,
               COMPANIA,
               RAMO,
               SECUENCIAL,
               SEC_POL,
               PLAN,
               USU_ING,
               FEC_APE,
               FEC_TRA,
               FEC_SER,
               TIP_REC,
               RECLAMANTE,
               TIP_A_USO,
               ASE_USO,
               DEP_USO,
               NUM_PLA,
               TIP_SER,
               RIE_LAB,
               CAU_NO_SIMULT,
               TIP_R_LAB,
               FEC_CON,
               USU_CON,
               ANO_PRECERT,
               NUM_PRECERT,
               CANAL
          FROM RECLAMACION
         WHERE ANO = FONOS_ROW.ANO_REC
           AND COMPANIA = FONOS_ROW.COMPANIA
           AND RAMO = FONOS_ROW.RAMO
           AND SECUENCIAL = FONOS_ROW.SEC_REC
           AND ESTATUS = V_83 -- APERTURADA VIA TELEF.
           AND SEC_R_HOS IS NULL;

      vRECLAMAC_ROW REC_C%ROWTYPE;

      CURSOR COB_C IS
        SELECT SERVICIO,
               TIP_COB,
               COBERTURA,
               FRECUENCIA,
               MON_REC,
               RESERVA,
               61 ESTATUS,
               LIM_AFI,
               TIP_REC,
               RECLAMANTE,
               COMENT,
               POR_COA,
               POR_DES,
               MON_PAG,
               RAM_POL,
               SEC_POL,
               MON_SIM,
               MON_COASEG,
               NVL(EXCEDENTE_COPAGO, 0) EXCEDENTE_COPAGO
          FROM RECLAMACION_COBERTURA_SALUD
         WHERE ANO = FONOS_ROW.ANO_REC
           AND COMPANIA = FONOS_ROW.COMPANIA
           AND RAMO = FONOS_ROW.RAMO
           AND SECUENCIAL = FONOS_ROW.SEC_REC
         ORDER BY SECUENCIA;

    BEGIN
      OPEN A;
      FETCH A
        INTO FONOS_ROW.ANO_REC,
             FONOS_ROW.COMPANIA,
             FONOS_ROW.RAMO,
             FONOS_ROW.SEC_REC,
             FONOS_ROW.TIP_SER;
      IF A%FOUND THEN
        IF Instr(vSERVICIO_PARAM, FONOS_ROW.TIP_SER) > 0 THEN
          --
          OPEN REC_C;
          FETCH REC_C
            INTO vRECLAMAC_ROW;
          IF REC_C%FOUND THEN
            -- Genera secuencias del ingreso
            vNUM_INGRESO        := DBAPER.PAQ_RECLAMACION.P_SECUENCIA_RECLAMACION('REP_HOS');
            vRECLAMAC_ROW.CANAL := PKG_PRE_CERTIFICACIONES.F_OBTEN_CANAL_AUT(vRECLAMAC_ROW.USU_ING);
            --
            INSERT INTO REPORTE_HOSPITALIZACION
              (ANO,
               SECUENCIAL,
               TIP_REC,
               NO_MEDICO,
               TIP_P_HOS,
               PER_HOS,
               DEP_USO,
               COM_POL,
               RAM_POL,
               SEC_POL,
               PLA_POL,
               SERVICIO,
               FEC_ING,
               ESTATUS,
               FEC_TRA,
               USU_ING,
               FECHA_ALTA,
               FEC_SAL,
               USU_SAL,
               RIE_LAB,
               CAU_NO_SIMULT,
               FOR_PRO,
               TIP_R_LAB,
               NUM_PLA,
               ANO_REC,
               SEC_REC,
               ANO_PRECERT,
               NUM_PRECERT,
               CANAL)
            VALUES
              (vRECLAMAC_ROW.ANO,
               vNUM_INGRESO,
               vRECLAMAC_ROW.TIP_REC,
               vRECLAMAC_ROW.RECLAMANTE,
               vRECLAMAC_ROW.TIP_A_USO,
               vRECLAMAC_ROW.ASE_USO,
               vRECLAMAC_ROW.DEP_USO,
               vRECLAMAC_ROW.COMPANIA,
               vRECLAMAC_ROW.RAMO,
               vRECLAMAC_ROW.SEC_POL,
               vRECLAMAC_ROW.PLAN,
               vRECLAMAC_ROW.TIP_SER,
               vRECLAMAC_ROW.FEC_SER,
               vEST_REP_CONVERTIDA,
               vRECLAMAC_ROW.FEC_TRA,
               vRECLAMAC_ROW.USU_ING,
               vRECLAMAC_ROW.FEC_TRA,
               vRECLAMAC_ROW.FEC_TRA,
               vRECLAMAC_ROW.USU_ING,
               vRECLAMAC_ROW.RIE_LAB,
               vRECLAMAC_ROW.CAU_NO_SIMULT,
               'NORMAL',
               vRECLAMAC_ROW.TIP_R_LAB,
               vRECLAMAC_ROW.NUM_PLA,
               vRECLAMAC_ROW.ANO,
               vRECLAMAC_ROW.SECUENCIAL,
               vRECLAMAC_ROW.ANO_PRECERT,
               vRECLAMAC_ROW.NUM_PRECERT,
               vRECLAMAC_ROW.CANAL);
            --
            OPEN COB_C;
            LOOP
              FETCH COB_C
                INTO vCOB_ROW.SERVICIO,
                     vCOB_ROW.TIP_COB,
                     vCOB_ROW.COBERTURA,
                     vCOB_ROW.FRECUENCIA,
                     vCOB_ROW.MON_REC,
                     vCOB_ROW.RESERVA,
                     vCOB_ROW.ESTATUS,
                     vCOB_ROW.LIM_AFI,
                     vCOB_ROW.TIP_REC,
                     vCOB_ROW.RECLAMANTE,
                     vCOB_ROW.COMENT,
                     vCOB_ROW.POR_COA,
                     vCOB_ROW.POR_DES,
                     vCOB_ROW.MON_PAG,
                     vCOB_ROW.RAM_POL,
                     vCOB_ROW.SEC_POL,
                     vCOB_ROW.MON_SIM,
                     vCOB_ROW.MON_COASEG,
                     vCOB_ROW.EXCEDENTE_COPAGO;
              EXIT WHEN COB_C%NOTFOUND;
              --
              vSECUENCIA := vSECUENCIA + V_1;
              --
              INSERT INTO REP_H_COB
                (ANO,
                 SECUENCIAL,
                 SECUENCIA,
                 SERVICIO,
                 TIP_COB,
                 COBERTURA,
                 FEC_SER,
                 FRECUENCIA,
                 MON_REC,
                 RESERVA,
                 ESTATUS,
                 LIM_AFI,
                 TIP_AFI,
                 AFI_REC,
                 COMENT,
                 POR_COA,
                 POR_DES,
                 MON_PAG,
                 COM_POL,
                 RAM_POL,
                 SEC_POL,
                 MON_SIM,
                 MON_COASEG,
                 EXCEDENTE_COPAGO,
                 FEC_ING_COB,
                 USU_ING_COB)
              VALUES
                (vRECLAMAC_ROW.ANO,
                 vNUM_INGRESO,
                 vSECUENCIA,
                 vCOB_ROW.SERVICIO,
                 vCOB_ROW.TIP_COB,
                 vCOB_ROW.COBERTURA,
                 vRECLAMAC_ROW.FEC_SER,
                 vCOB_ROW.FRECUENCIA,
                 vCOB_ROW.MON_REC,
                 vCOB_ROW.RESERVA,
                 vCOB_ROW.ESTATUS,
                 vCOB_ROW.LIM_AFI,
                 vCOB_ROW.TIP_REC,
                 vCOB_ROW.RECLAMANTE,
                 vCOB_ROW.COMENT,
                 vCOB_ROW.POR_COA,
                 vCOB_ROW.POR_DES,
                 vCOB_ROW.MON_PAG,
                 vRECLAMAC_ROW.COMPANIA,
                 vRECLAMAC_ROW.RAMO,
                 vCOB_ROW.SEC_POL,
                 vCOB_ROW.MON_SIM,
                 vCOB_ROW.MON_COASEG,
                 vCOB_ROW.EXCEDENTE_COPAGO,
                 vRECLAMAC_ROW.FEC_TRA,
                 vRECLAMAC_ROW.USU_ING);
              --
            END LOOP;
            CLOSE COB_C;

          END IF;
          CLOSE REC_C;
          -- Relaciona reclamacion con ingreso
          UPDATE RECLAMACION
             SET ANO_R_HOS = vRECLAMAC_ROW.ANO, SEC_R_HOS = vNUM_INGRESO
           WHERE ANO = FONOS_ROW.ANO_REC
             AND COMPANIA = FONOS_ROW.COMPANIA
             AND RAMO = FONOS_ROW.RAMO
             AND SECUENCIAL = FONOS_ROW.SEC_REC;
          --
        END IF;
      END IF;
      CLOSE A;
    END;
  END;
  -- ******************************************************************** --
  PROCEDURE P_OPEN_PRECERTIF(p_name       IN VARCHAR2,
                             p_numsession IN NUMBER,
                             p_instr1     IN VARCHAR2,
                             p_instr2     IN VARCHAR2,
                             p_innum1     IN NUMBER,
                             p_innum2     IN NUMBER,
                             p_outstr1    OUT VARCHAR2,
                             p_outstr2    OUT VARCHAR2,
                             p_outnum1    OUT NUMBER,
                             p_outnum2    OUT NUMBER) IS
  BEGIN
    DECLARE
      FECHA_DIA       DATE;
      VAR_CODE        NUMBER(2) := 1;
      SEC_PRECERTIF   NUMBER;
      vNUM_INGRESO    NUMBER;
      VAR_ANO_REC     NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));
      VAR_PRE_FIJO    NUMBER := 7;
      VAR_ESTATUS     NUMBER := 734; -- Pre-Certifiacion Aperturada
      VAR_RECLAMANTE  NUMBER(14);
      VAR_ASEGURADO   VARCHAR2(15);
      VAR_DEPENDIENTE VARCHAR2(3);
      VAR_COMPANIA    NUMBER(2);
      VAR_RAMO        NUMBER(2);
      VAR_SECUENCIAL  NUMBER(7);
      VAR_PLAN        NUMBER(3);
      VAR_TIP_REC     VARCHAR2(10);
      VAR_TIP_SER     NUMBER(2);
      VAR_TIP_A_USO   VARCHAR2(10);
      VAR_ASE_USO     NUMBER(11);
      VAR_DEP_USO     NUMBER(3);
      VAR_MED_TRA     NUMBER(7);
      VAR_RIE_LAB     VARCHAR2(1);
      VAR_NUM_PLA     VARCHAR2(20);
      VAR_TIP_COB     NUMBER(3);

      CURSOR C IS
        SELECT AFILIADO,
               ASEGURADO,
               DEPENDIENTE,
               COMPANIA,
               RAMO,
               SECUENCIAL,
               PLAN,
               TIP_REC,
               TIP_SER,
               MED_TRA,
               RIE_LAB,
               ASE_CARNET,
               TIP_COB
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION
           FOR UPDATE;

    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

      FECHA_DIA   := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      VAR_ANO_REC := TO_CHAR(SYSDATE, 'YYYY');
      --
      OPEN C;
      FETCH C
        INTO VAR_RECLAMANTE,
             VAR_ASEGURADO,
             VAR_DEPENDIENTE,
             VAR_COMPANIA,
             VAR_RAMO,
             VAR_SECUENCIAL,
             VAR_PLAN,
             VAR_TIP_REC,
             VAR_TIP_SER,
             VAR_MED_TRA,
             VAR_RIE_LAB,
             VAR_NUM_PLA,
             VAR_TIP_COB;
      IF C%FOUND THEN
        -- Genera secuencia Pre-Certificacion
        SEC_PRECERTIF := PKG_PRE_CERTIFICACIONES.F_GET_SECUENCIAL('PRE_CERTIFICACION');

        vNUM_INGRESO := PKG_PRE_CERTIFICACIONES.F_SECUENCIA_PREFIJO('PRE_CERTIFICACION',
                                                                    VAR_ANO_REC,
                                                                    SEC_PRECERTIF);
        --
        VAR_ASE_USO := TO_NUMBER(VAR_ASEGURADO);
        VAR_DEP_USO := TO_NUMBER(VAR_DEPENDIENTE);
        --
        IF NVL(VAR_DEP_USO, 0) > 0 THEN
          VAR_TIP_A_USO := 'DEPENDIENT';
        ELSE
          VAR_TIP_A_USO := 'ASEGURADO';
          VAR_DEP_USO   := 0;
        END IF;

        INSERT INTO PRE_CERTIFICACION
          (ANO,
           SECUENCIAL,
           NUM_PRECERT,
           COM_POL,
           RAM_POL,
           SEC_POL,
           PLA_POL,
           TIP_REC,
           NO_MEDICO,
           TIP_P_HOS,
           PER_HOS,
           FEC_ING,
           FEC_TRA,
           USU_ING,
           ESTATUS,
           SERVICIO,
           MOTIVO_ESTATUS,
           DEP_USO,
           --FEC_SAL,
           MED_TRA,
           COMENT,
           RIE_LAB,
           NUM_PLA,
           PRE_FIJO,
           FOR_PRO)
        VALUES
          (VAR_ANO_REC,
           SEC_PRECERTIF,
           vNUM_INGRESO,
           VAR_COMPANIA,
           VAR_RAMO,
           VAR_SECUENCIAL,
           VAR_PLAN,
           VAR_TIP_REC,
           VAR_RECLAMANTE,
           VAR_TIP_A_USO,
           VAR_ASE_USO,
           FECHA_DIA,
           SYSDATE,
           vUsuario,
           VAR_ESTATUS,
           VAR_TIP_SER,
           NULL,
           VAR_DEP_USO,
           --FECHA_DIA,
           VAR_MED_TRA,
           'PRE-CERTIFICACION VIA ' || vUSUARIO,
           VAR_RIE_LAB,
           VAR_NUM_PLA,
           VAR_PRE_FIJO,
           'NORMAL');

        VAR_CODE := 0;

        UPDATE INFOX_SESSION
           SET CODE        = VAR_CODE,
               ANO_REC     = VAR_ANO_REC,
               SEC_REC     = SEC_PRECERTIF,
               RECLAMACION = LTRIM(TO_CHAR(SEC_PRECERTIF))
         WHERE CURRENT OF C;

      END IF;
      CLOSE C;
      P_OUTNUM1 := VAR_CODE;
      P_OUTSTR1 := SEC_PRECERTIF;
      P_OUTSTR2 := VAR_RAMO;
    END;
  END;
  -- ******************************************************************** --
  PROCEDURE P_INSERTCOBERTURA_PRECERTIF(p_name       IN VARCHAR2,
                                        p_numsession IN NUMBER,
                                        p_instr1     IN VARCHAR2,
                                        p_instr2     IN VARCHAR2,
                                        p_innum1     IN NUMBER,
                                        p_innum2     IN NUMBER,
                                        p_outstr1    OUT VARCHAR2,
                                        p_outstr2    OUT VARCHAR2,
                                        p_outnum1    OUT NUMBER,
                                        p_outnum2    OUT NUMBER) IS
  BEGIN

    DECLARE
      FONOS_ROW      INFOX_SESSION%ROWTYPE;
      FECHA_DIA      DATE;
      VAR_CODE       NUMBER(2) := 1;
      VAR_RECLAMANTE NUMBER(14);
      VAR_TIP_REC    VARCHAR2(10);
      VAR_TIP_SER    NUMBER(2);
      VAR_TIP_COB    NUMBER(3);
      VAR_COBERTURA  NUMBER(5);
      VAR_MON_REC    NUMBER(11, 2);
      VAR_FEC_SER    DATE;
      VAR_ESTATUS    NUMBER(3) := 61;
      VAR_SECUENCIA  NUMBER(7);
      VAR_MON_PAG    NUMBER(11, 2);
      VAR_MON_DED    NUMBER(11, 2);
      VAR_POR_COA    NUMBER(11, 2);
      VAR_MON_COA    NUMBER(11, 2);

      CURSOR A IS
        SELECT FEC_ING
          FROM PRE_CERTIFICACION
         WHERE ANO = FONOS_ROW.ANO_REC
           AND COM_POL = FONOS_ROW.COMPANIA
           AND RAM_POL = FONOS_ROW.RAMO
           AND SECUENCIAL = FONOS_ROW.SEC_REC;

      CURSOR B IS
        SELECT NVL(MAX(SECUENCIA), 0) + V_1
          FROM PRE_C_COB
         WHERE ANO = FONOS_ROW.ANO_REC
           AND COM_POL = FONOS_ROW.COMPANIA
           AND RAM_POL = FONOS_ROW.RAMO
           AND SECUENCIAL = FONOS_ROW.SEC_REC;

      CURSOR C IS
        SELECT TIP_REC,
               AFILIADO,
               TIP_SER,
               TIP_COB,
               COBERTURA,
               ANO_REC,
               COMPANIA,
               RAMO,
               SECUENCIAL,
               SEC_REC,
               MON_REC,
               MON_PAG,
               MON_DED,
               POR_COA
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION;
    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario

      FECHA_DIA := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      OPEN C;
      FETCH C
        INTO VAR_TIP_REC,
             VAR_RECLAMANTE,
             VAR_TIP_SER,
             VAR_TIP_COB,
             VAR_COBERTURA,
             FONOS_ROW.ANO_REC,
             FONOS_ROW.COMPANIA,
             FONOS_ROW.RAMO,
             FONOS_ROW.SECUENCIAL,
             FONOS_ROW.SEC_REC,
             VAR_MON_REC,
             VAR_MON_PAG,
             VAR_MON_DED,
             VAR_POR_COA;
      IF C%FOUND THEN
        OPEN A;
        FETCH A
          INTO VAR_FEC_SER;
        IF A%FOUND THEN
          OPEN B;
          FETCH B
            INTO VAR_SECUENCIA;
          CLOSE B;
          VAR_MON_COA := VAR_MON_REC - VAR_MON_PAG;
          BEGIN
            INSERT INTO PRE_C_COB
              (ANO,
               SECUENCIAL,
               SECUENCIA,
               SERVICIO,
               TIP_COB,
               COBERTURA,
               FEC_SER,
               FRECUENCIA,
               MON_REC,
               RESERVA,
               ESTATUS,
               LIM_AFI,
               TIP_AFI,
               AFI_REC,
               POR_COA,
               POR_DES,
               MON_PAG,
               COM_POL,
               RAM_POL,
               SEC_POL,
               MON_COASEG,
               EXCEDENTE_COPAGO,
               FEC_ING_COB,
               USU_ING_COB,
               FEC_TRA,
               USU_TRA)
            VALUES
              (FONOS_ROW.ANO_REC,
               FONOS_ROW.SEC_REC,
               VAR_SECUENCIA,
               VAR_TIP_SER,
               VAR_TIP_COB,
               VAR_COBERTURA,
               VAR_FEC_SER,
               1, -- FREC
               VAR_MON_REC,
               VAR_MON_REC,
               VAR_ESTATUS,
               VAR_MON_REC,
               VAR_TIP_REC,
               VAR_RECLAMANTE,
               VAR_POR_COA,
               0, -- POR_DES
               VAR_MON_PAG,
               FONOS_ROW.COMPANIA,
               FONOS_ROW.RAMO,
               FONOS_ROW.SECUENCIAL,
               VAR_MON_COA,
               VAR_MON_DED,
               SYSDATE,
               vUSUARIO,
               SYSDATE,
               vUSUARIO);

            --ACUMULAR CAMPO TOT_MON_DED--
            UPDATE INFOX_SESSION
               SET TOT_MON_DED = NVL(TOT_MON_DED, 0) + NVL(VAR_MON_DED, 0)
             WHERE NUMSESSION = P_NUMSESSION;

            VAR_CODE := 0;
          /*EXCEPTION
            WHEN OTHERS THEN
              VAR_CODE := 1;*/
          END;
        ELSE
          VAR_CODE := 1;
        END IF;
        CLOSE A;
      END IF;
      CLOSE C;
      P_OUTNUM1 := VAR_CODE;
    END;
  END;
  -- ******************************************************************** --
  PROCEDURE P_CLOSE_PRECERTIFICACION(p_name       IN VARCHAR2,
                                     p_numsession IN NUMBER,
                                     p_instr1     IN VARCHAR2,
                                     p_instr2     IN VARCHAR2,
                                     p_innum1     IN NUMBER,
                                     p_innum2     IN NUMBER,
                                     p_outstr1    OUT VARCHAR2,
                                     p_outstr2    OUT VARCHAR2,
                                     p_outnum1    OUT NUMBER,
                                     p_outnum2    OUT NUMBER) IS
  BEGIN
    /* Descripcion : Realmente no cambia ningun estatus, la reclamacion ya fue creada con estatus definitivo.*/
    /*               Retorno el total general a pagar por ars y por el asegurado*/
    DECLARE
      FECHA_DIA       DATE;
      VAR_CODE        NUMBER(2) := 1;
      ANO_REC         NUMBER(4);
      VAR_MON_PAG     NUMBER(16, 2);
      VAR_MON_DED     NUMBER(16, 2);
      FONOS_ROW       INFOX_SESSION%ROWTYPE;
      V_ERROR_MESSAGE VARCHAR2(2000);

      PRECERT_ROW     PRE_CER%ROWTYPE;
      vTIPO_PRECERTIF VARCHAR2(1);

      CURSOR A IS
        SELECT ANO_REC,
               SEC_REC,
               AFILIADO,
               TIP_REC,
               COMPANIA,
               RAMO,
               TOT_MON_DED
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION
           FOR UPDATE;

      CURSOR B IS
        SELECT ESTATUS, SEC_R_HOS, SEC_REC, SERVICIO
          FROM PRE_CERTIFICACION
         WHERE ANO = FONOS_ROW.ANO_REC
           AND COM_POL = FONOS_ROW.COMPANIA
           AND RAM_POL = FONOS_ROW.RAMO
           AND SECUENCIAL = FONOS_ROW.SEC_REC
           AND TIP_REC = FONOS_ROW.TIP_REC
           AND NO_MEDICO = FONOS_ROW.AFILIADO;

      CURSOR C IS
        SELECT SUM(NVL(MON_PAG, 0))
          FROM PRE_C_COB
         WHERE ANO = FONOS_ROW.ANO_REC
           AND COM_POL = FONOS_ROW.COMPANIA
           AND RAM_POL = FONOS_ROW.RAMO
           AND SECUENCIAL = FONOS_ROW.SEC_REC;
    BEGIN

      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      FECHA_DIA := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      OPEN A;
      FETCH A
        INTO FONOS_ROW.ANO_REC,
             FONOS_ROW.SEC_REC,
             FONOS_ROW.AFILIADO,
             FONOS_ROW.TIP_REC,
             FONOS_ROW.COMPANIA,
             FONOS_ROW.RAMO,
             VAR_MON_DED;
      IF A%FOUND THEN

        ANO_REC := TO_NUMBER(SUBSTR(TO_CHAR(FECHA_DIA, 'DD/MM/YYYY'), 7, 4));
        OPEN B;
        FETCH B
          INTO PRECERT_ROW.ESTATUS,
               PRECERT_ROW.SEC_R_HOS,
               PRECERT_ROW.SEC_REC,
               PRECERT_ROW.SERVICIO;
        IF B%FOUND AND PRECERT_ROW.ESTATUS IN (734) THEN
          OPEN C;
          FETCH C
            INTO VAR_MON_PAG;
          CLOSE C;
          VAR_CODE := 0;
          -- Si la pre-certificacion esta pendiente de confirmacion no aplica este proceso
          --Se comento para que al momento de realizarse una pre-certificacion por el KIOSKO no se genere el documento sucesor Miguel A. Carrion 26/01/2021
         /** IF PRECERT_ROW.SEC_R_HOS IS NULL AND PRECERT_ROW.SEC_REC IS NULL THEN
            --
            vTIPO_PRECERTIF := PKG_PRE_CERTIFICACIONES.F_OBTEN_TIPO_PRECERTIF(PRECERT_ROW.SERVICIO);
            IF vTIPO_PRECERTIF = 'A' THEN
              vTIPO_PRECERTIF := 'R'; -- Reclamacion
            END IF;
            -- Proceso convertir pre-certificacion en Autorizacion
            PKG_PRE_CERTIFICACIONES.p_AUTORIZA_PRE_CERTIFICACION(ANO_REC,
                                                                 FONOS_ROW.COMPANIA,
                                                                 FONOS_ROW.RAMO,
                                                                 FONOS_ROW.SEC_REC,
                                                                 FECHA_DIA,
                                                                 vTIPO_PRECERTIF,
                                                                 vUSUARIO,
                                                                 vCANAL);
          END IF;***/
        ELSE
          VAR_CODE := 1;
        END IF;
        CLOSE B;
        --
        UPDATE INFOX_SESSION SET CODE = VAR_CODE WHERE CURRENT OF A;
      END IF;
      CLOSE A;
      P_OUTNUM1 := VAR_CODE;
      P_OUTSTR1 := ltrim(to_char(NVL(VAR_MON_PAG, 0), '999999990.00'));
      P_OUTSTR2 := ltrim(to_char(NVL(VAR_MON_DED, 0), '999999990.00'));
      --
    END;

  END;
  -- ******************************************************************** --
  PROCEDURE p_ACTIVAR_PRECERTIFICACION(p_name       IN VARCHAR2,
                                       p_numsession IN NUMBER,
                                       p_instr1     IN VARCHAR2, -- NUM_PRECERTIF
                                       p_instr2     IN VARCHAR2,
                                       p_innum1     IN NUMBER,
                                       p_innum2     IN NUMBER,
                                       p_outstr1    OUT VARCHAR2,
                                       p_outstr2    OUT VARCHAR2,
                                       p_outnum1    OUT NUMBER,
                                       p_outnum2    OUT NUMBER) IS
  BEGIN
    DECLARE

      FONOS_ROW           INFOX_SESSION%ROWTYPE;
      PRECERT_ROW         PRE_CER%ROWTYPE;
      VAR_CODE            NUMBER(2) := 1;
      PRE_COB_ROW         PRE_C_COB%ROWTYPE;
      EST_PRE_CERTIFICADA PRE_CER.ESTATUS%TYPE := 734; /* Almacena el Estatus Vigente de Pre-certificacion. */
      vEST_PRE_CONVERTIDA PRE_CER.ESTATUS%TYPE := 735;
      vFECHA_DIA          DATE;
      vTIPO_PRECERTIF     VARCHAR2(1);
      V_ESTATUS           NUMBER ;

                                              
                                                                
                                            
                                               
                                       
                                             
                                            
                                                       
                                                  
                                   
                                                                      
                                              
                                           

                 
                                   
                                          
                                    
                                            
                                            
      CURSOR B IS
        SELECT A.ANO,
               A.COM_POL,
               A.RAM_POL,
               A.SECUENCIAL,
               A.SEC_POL,
               A.PER_HOS,
               A.DEP_USO,
               A.FEC_TRA,
               A.PLA_POL,
               A.SERVICIO,
               A.ESTATUS,
               A.SEC_R_HOS,
               A.SEC_REC,
               Nvl(A.CHK_AMB,'N'),
               Nvl(A.CHK_CIR,'N')
          FROM PRE_CERTIFICACION A
         WHERE /*A.PER_HOS = FONOS_ROW.ASEGURADO
           AND NVL(A.DEP_USO, 0) = NVL(FONOS_ROW.DEPENDIENTE, 0)
           AND */A.TIP_REC = FONOS_ROW.TIP_REC           
           AND A.NO_MEDICO = FONOS_ROW.AFILIADO 
           AND A.SECUENCIAL = p_INSTR1
           AND A.ESTATUS IN  (SELECT E.CODIGO
                              FROM ESTATUS E
                              WHERE TIPO = 'PRE_CERTIFICACION'
                               AND VAL_LOG = 'T');
           /*FOR UPDATE SKIP LOCKED
           Se comenta ya que no esta utilizando la clausula current of
           y el mismo no actualiza el registro
           por Tyler Almonte -06/06/2022 */

      CURSOR C IS
        SELECT SUM(NVL(MON_PAG, 0))
          FROM PRE_CERTIFICACION_COBERTURA
         WHERE ANO = PRECERT_ROW.ANO
           AND COM_POL = PRECERT_ROW.COM_POL
           AND RAM_POL = PRECERT_ROW.RAM_POL
           AND SECUENCIAL = PRECERT_ROW.SECUENCIAL;

      CURSOR D IS
        SELECT NO_MEDICO.TIP_N_MED, TIP_N_MED.DESCRIPCION
          FROM NO_MEDICO, TIPO_NO_MEDICO TIP_N_MED
         WHERE NO_MEDICO.CODIGO = FONOS_ROW.AFILIADO
           AND TIP_N_MED.CODIGO = NO_MEDICO.TIP_N_MED;

      TIP_N_MED_ROW  TIPO_NO_MEDICO%ROWTYPE;
      vSEC_PRECERTIF NUMBER;

      CURSOR P IS
        SELECT DECODE(vTIPO_PRECERTIF, 'I', SEC_R_HOS, SEC_REC)
          FROM PRE_CERTIFICACION
         WHERE ANO = PRECERT_ROW.ANO
           AND COM_POL = PRECERT_ROW.COM_POL
           AND RAM_POL = PRECERT_ROW.RAM_POL
           AND SECUENCIAL = PRECERT_ROW.SECUENCIAL;
       /*Se crea cursor H para el manejo de las consulta ambulatorias que viajan como ingreso para que retorne el secuencial de hospitalizacion
       por Tyler Almonte 21/06/2022 */
       CURSOR H IS
        SELECT  SEC_R_HOS
          FROM PRE_CERTIFICACION
         WHERE ANO = PRECERT_ROW.ANO
           AND COM_POL = PRECERT_ROW.COM_POL
           AND RAM_POL = PRECERT_ROW.RAM_POL
           AND SECUENCIAL = PRECERT_ROW.SECUENCIAL;
      /*Se crea cursor para validar el estatus de la poliza , ya que solo debe estar vigente otro estatus 
      diferente a este no debe de activarse . by tyler almonte 05/08/2022*/     
           
       CURSOR P_POL_EST (P_COM NUMBER , P_RAM NUMBER , P_SEC NUMBER ) IS 
              SELECT ESTATUS
                  FROM POLIZA  P
                WHERE P.COMPANIA =P_COM
                AND   P.RAMO =P_RAM
                AND   P.SECUENCIAL =P_SEC
                AND   P.FEC_VER = (SELECT MAX(FEC_VER)
                                      FROM POLIZA PP
                                    WHERE PP.COMPANIA=P.COMPANIA
                                    AND   PP.RAMO =P.RAMO
                                    AND   PP.SECUENCIAL=P.SECUENCIAL ) ;    

    BEGIN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      vFECHA_DIA := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY'), 'DD/MM/YYYY');
     
         BEGIN
               
          SELECT TIP_REC,AFILIADO 
            
            INTO FONOS_ROW.TIP_REC, FONOS_ROW.AFILIADO
              FROM INFOX_SESSION
             WHERE NUMSESSION = P_NUMSESSION;
         EXCEPTION 
         WHEN NO_DATA_FOUND THEN
           VAR_CODE := 1;
                           
                 
                 
                                     
                  
         
         END;
              
                                                                                                    

                                                    
        OPEN B;
        FETCH B
          INTO PRECERT_ROW.ANO,
               PRECERT_ROW.COM_POL,
               PRECERT_ROW.RAM_POL,
               PRECERT_ROW.SECUENCIAL,
               PRECERT_ROW.SEC_POL,
               PRECERT_ROW.PER_HOS,
               PRECERT_ROW.DEP_USO,
               PRECERT_ROW.FEC_TRA,
               PRECERT_ROW.PLA_POL,
               PRECERT_ROW.SERVICIO,
               PRECERT_ROW.ESTATUS,
               PRECERT_ROW.SEC_R_HOS,
               PRECERT_ROW.SEC_REC,
               PRECERT_ROW.CHK_AMB,
               PRECERT_ROW.CHK_CIR;
               
            OPEN P_POL_EST (PRECERT_ROW.COM_POL,
                            PRECERT_ROW.RAM_POL,
                            PRECERT_ROW.SEC_POL);
           FETCH P_POL_EST INTO V_ESTATUS;
           CLOSE P_POL_EST ;
               

        IF PRECERT_ROW.ESTATUS =  EST_PRE_CERTIFICADA AND V_ESTATUS =37 THEN
          VAR_CODE := 0;
          OPEN C;
          FETCH C
            INTO PRE_COB_ROW.MON_PAG;
          CLOSE C;
          -- Para solo ejecutar proceso si esta en estatus vigente
          IF PRECERT_ROW.ESTATUS = est_pre_certificada THEN
            --
            vTIPO_PRECERTIF := PKG_PRE_CERTIFICACIONES.F_OBTEN_TIPO_PRECERTIF(PRECERT_ROW.SERVICIO);
            IF vTIPO_PRECERTIF = 'A' THEN
              vTIPO_PRECERTIF := 'R'; -- Reclamacion
            END IF;

            IF PRECERT_ROW.CHK_AMB = 'S' THEN
             --
             vTIPO_PRECERTIF := 'R'; -- Reclamacion
             --
            ELSIF  PRECERT_ROW.CHK_AMB = 'N' AND PRECERT_ROW.CHK_CIR='S' THEN
              vTIPO_PRECERTIF := 'I';

            END IF;

            -- Si la pre-certificacion esta pendiente de confirmacion no aplica este proceso
            IF PRECERT_ROW.SEC_R_HOS IS NULL AND
               PRECERT_ROW.SEC_REC IS NULL THEN
              -- Proceso convertir pre-certificacion en Ingreso o Autorizacion
              PKG_PRE_CERTIFICACIONES.p_AUTORIZA_PRE_CERTIFICACION(PRECERT_ROW.ANO,
                                                                   PRECERT_ROW.COM_POL,
                                                                   PRECERT_ROW.RAM_POL,
                                                                   PRECERT_ROW.SECUENCIAL,
                                                                   vFECHA_DIA,
                                                                   vTIPO_PRECERTIF,
                                                                   vUsuario,
                                                                   vCANAL);
            END IF;

            -- Proceso confirmar pre-certificacion
            PKG_PRE_CERTIFICACIONES.p_CONFIRMAR_PRE_CERTIFICACION(PRECERT_ROW.ANO,
                                                                  PRECERT_ROW.COM_POL,
                                                                  PRECERT_ROW.RAM_POL,
                                                                  PRECERT_ROW.SECUENCIAL,
                                                                  vUsuario,
                                                                  vCANAL,
                                                                  'P');

            -- Busca el secuencial de ingreso o reclamacion
            OPEN P;
            FETCH P
              INTO vSEC_PRECERTIF;
            CLOSE P;

            /*Se crea condicion que para validar el numero de ingreso y retornarlo si no lo encuentra en el cursor P
            esta condicion es para los casos que son ambulatorio y viajan como ingreso ,por Tyler Almonte 21/06/2022*/
            IF vSEC_PRECERTIF IS NULL THEN
              OPEN H;
            FETCH H
              INTO vSEC_PRECERTIF;
            CLOSE H;
            END IF;


          END IF;
          --
          UPDATE INFOX_SESSION
             SET ANO_REC     = PRECERT_ROW.ANO,
                 COMPANIA    = PRECERT_ROW.COM_POL,
                 RAMO        = PRECERT_ROW.RAM_POL,
                 SEC_REC     = PRECERT_ROW.SECUENCIAL,
                 RECLAMACION = PRECERT_ROW.SECUENCIAL,
                 ASEGURADO   = PRECERT_ROW.PER_HOS,
                 DEPENDIENTE = PRECERT_ROW.DEP_USO,
                 MON_REC     = PRE_COB_ROW.MON_PAG,
                 FEC_APE     = PRECERT_ROW.FEC_TRA,
                 PLAN        = PRECERT_ROW.PLA_POL,
                 TIP_SER     = PRECERT_ROW.SERVICIO
           WHERE NUMSESSION = P_NUMSESSION;
          --

          ELSIF
                 PRECERT_ROW.ESTATUS =  vEST_PRE_CONVERTIDA  THEN
                  VAR_CODE := 0;
                 -- Busca el secuencial de ingreso o reclamacion
            OPEN P;
            FETCH P
              INTO vSEC_PRECERTIF;
            CLOSE P;
            /*Se crea condicion que para validar el numero de ingreso y retornarlo si no lo encuentra en el cursor P
            esta condicion es para los casos que son ambulatorio y viajan como ingreso ,por Tyler Almonte 21/06/2022*/
            IF vSEC_PRECERTIF IS NULL THEN
              OPEN H;
            FETCH H
              INTO vSEC_PRECERTIF;
            CLOSE H;
            END IF;


             vTIPO_PRECERTIF := PKG_PRE_CERTIFICACIONES.F_OBTEN_TIPO_PRECERTIF(PRECERT_ROW.SERVICIO);
            IF vTIPO_PRECERTIF = 'A' THEN
              vTIPO_PRECERTIF := 'R'; -- Reclamacion
            END IF;

            IF PRECERT_ROW.CHK_AMB = 'S' THEN
             --
             vTIPO_PRECERTIF := 'R'; -- Reclamacion
             --

            END IF;

        END IF;
        CLOSE B;
               
                          

      UPDATE INFOX_SESSION
         SET CODE     = VAR_CODE,
             USUARIO  = UPPER(vUsuario),
             TERMINO  = SYSDATE,
             DURACION = TO_NUMBER(TO_CHAR(SYSDATE, 'HHMISS')) -
                        TO_NUMBER(TO_CHAR(INICIO, 'HHMISS'))
       WHERE NUMSESSION = P_NUMSESSION;

      p_OUTNUM1 := VAR_CODE;
      P_OUTSTR1 := vSEC_PRECERTIF;
      P_OUTSTR2 := vTIPO_PRECERTIF;
      COMMIT;

    END;
  END;
  -- ******************************************************************** --
  FUNCTION BUSCA_ORIGEN_COB_MON_MAX(P_SERVICIO  IN NUMBER,
                                    P_TIP_COB   IN NUMBER,
                                    P_COBERTURA IN NUMBER,
                                    P_ORIGEN    IN VARCHAR2) RETURN NUMBER IS

    v_MONTO_MAXIMO NUMBER(11, 2);

    CURSOR C_WS IS
      SELECT NVL(MON_MAX, 0)
        FROM COBERTURAS_WS
       WHERE SERVICIO = P_SERVICIO
         AND TIP_COB = P_TIP_COB
         AND COBERTURA = P_COBERTURA
         AND ORIGEN = P_ORIGEN;
  BEGIN
    OPEN C_WS;
    FETCH C_WS
      INTO v_MONTO_MAXIMO;
    CLOSE C_WS;
    RETURN v_MONTO_MAXIMO;
  END;
  -- ******************************************************************** --
  FUNCTION BUSCA_COB_ESTUDIO_REPETICION(p_ASE_USO   IN NUMBER,
                                        P_DEP_USO   IN NUMBER,
                                        p_COMPANIA  IN NUMBER,
                                        p_RAMO      IN NUMBER,
                                        p_SEC_POL   IN NUMBER,
                                        P_SERVICIO  IN NUMBER,
                                        P_TIP_COB   IN NUMBER,
                                        P_COBERTURA IN NUMBER,
                                        P_ORIGEN    IN VARCHAR2)
    RETURN VARCHAR2 IS

    VAR_DUMMY           VARCHAR2(1);
    vEST_PRE_CONVERTIDA PRE_CER.ESTATUS%TYPE := 735;

    CURSOR C_WS IS
      SELECT 'S'
        FROM COBERTURAS_WS
       WHERE /*SERVICIO = P_SERVICIO
         AND TIP_COB = P_TIP_COB
         AND*/ COBERTURA = P_COBERTURA
         AND NVL(ESTUDIO_REPETICION, 'N') = 'S'
         AND ORIGEN = P_ORIGEN;

    CURSOR COB_C IS
      SELECT 'S'
        FROM PRE_C_COB01_V
       WHERE COM_POL = p_COMPANIA
         AND RAM_POL = p_RAMO
         AND SEC_POL = p_SEC_POL
         AND PER_HOS = p_ASE_USO
         AND NVL(DEP_USO, 0) = NVL(P_DEP_USO, 0)
         AND ESTATUS = vEST_PRE_CONVERTIDA -- Convertida
         AND SERVICIO = p_SERVICIO
         AND TIP_COB = p_TIP_COB
         AND COBERTURA = p_COBERTURA;
  BEGIN
    OPEN C_WS;
    FETCH C_WS
      INTO VAR_DUMMY;
    --
    IF C_WS%FOUND THEN
      OPEN COB_C;
      FETCH COB_C
        INTO VAR_DUMMY;
      CLOSE COB_C;
    END IF;
    --
    CLOSE C_WS;
    RETURN VAR_DUMMY;
  END;
  /*******************************************************************************************************/
  -- Procedimiento principal para cualquier operacion Via IVR--
  -- cualquier procedure o funcion sera invocada a traves de este procedimiento--
  PROCEDURE infoxproc(p_name       IN VARCHAR2,
                      p_numsession IN NUMBER,
                      p_instr1     IN VARCHAR2,
                      p_instr2     IN VARCHAR2,
                      p_innum1     IN NUMBER,
                      p_innum2     IN NUMBER,
                      p_outstr1    OUT VARCHAR2,
                      p_outstr2    OUT VARCHAR2,
                      p_outnum1    OUT NUMBER,
                      p_outnum2    OUT NUMBER) IS
  BEGIN
    IF upper(p_name) = 'GETPIN' THEN
      select pin
        into p_outnum1
        from fonos_pin_afiliado
       where tip_afi = 'MEDICO'
         AND AFILIADO = p_instr1;
    ELSIF UPPER(P_NAME) = 'RIESGOSLABORALES' THEN
      UPDATE INFOX_SESSION
         SET RIE_LAB = V_S
       WHERE NUMSESSION = P_NUMSESSION;
    ELSIF upper(p_name) = 'VALIDATEPINTRATANTE' THEN
      P_VALIDATEPINTRATANTE(p_name,
                            p_numsession,
                            p_instr1,
                            p_instr2,
                            p_innum1,
                            p_innum2,
                            p_outstr1,
                            p_outstr2,
                            p_outnum1,
                            p_outnum2);
    ELSIF upper(p_name) = 'VALIDATEPIN' THEN
      P_VALIDATEPIN(p_name,
                    p_numsession,
                    p_instr1,
                    p_instr2,
                    p_innum1,
                    p_innum2,
                    p_outstr1,
                    p_outstr2,
                    p_outnum1,
                    p_outnum2);
    ELSIF upper(p_name) = 'VALIDATEASEGURADO' THEN
      P_VALIDATEASEGURADO(p_name,
                          p_numsession,
                          p_instr1,
                          p_instr2,
                          p_innum1,
                          p_innum2,
                          p_outstr1,
                          p_outstr2,
                          p_outnum1,
                          p_outnum2);
    ELSIF upper(p_name) = 'VALIDATERECLAMACION' THEN
      P_VALIDATERECLAMACION(p_name,
                            p_numsession,
                            p_instr1,
                            p_instr2,
                            p_innum1,
                            p_innum2,
                            p_outstr1,
                            p_outstr2,
                            p_outnum1,
                            p_outnum2);
    ELSIF upper(p_name) = 'VALIDATECOBERTURA' THEN
      P_VALIDATECOBERTURA(p_name,
                          p_numsession,
                          p_instr1,
                          p_instr2,
                          p_innum1,
                          p_innum2,
                          p_outstr1,
                          p_outstr2,
                          p_outnum1,
                          p_outnum2);
    ELSIF upper(p_name) = 'INSERTCOBERTURA' THEN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      IF vUSUARIO = 'KIOSKO' THEN
        P_INSERTCOBERTURA_PRECERTIF(p_name,
                                    p_numsession,
                                    p_instr1,
                                    p_instr2,
                                    p_innum1,
                                    p_innum2,
                                    p_outstr1,
                                    p_outstr2,
                                    p_outnum1,
                                    p_outnum2);
      ELSE
        P_INSERTCOBERTURA(p_name,
                          p_numsession,
                          p_instr1,
                          p_instr2,
                          p_innum1,
                          p_innum2,
                          p_outstr1,
                          p_outstr2,
                          p_outnum1,
                          p_outnum2);
      END IF;
    ELSIF upper(p_name) = 'OPENSESSION' THEN
      P_OPENSESSION(p_name,
                    p_numsession,
                    p_instr1,
                    p_instr2,
                    p_innum1,
                    p_innum2,
                    p_outstr1,
                    p_outstr2,
                    p_outnum1,
                    p_outnum2);
    ELSIF upper(p_name) = 'CLOSESESSION' THEN
      P_CLOSESESSION(p_name,
                     p_numsession,
                     p_instr1,
                     p_instr2,
                     p_innum1,
                     p_innum2,
                     p_outstr1,
                     p_outstr2,
                     p_outnum1,
                     p_outnum2);
    ELSIF upper(p_name) = 'OPENRECLAMACION' THEN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      IF vUSUARIO = 'KIOSKO' THEN
        P_OPEN_PRECERTIF(p_name,
                         p_numsession,
                         p_instr1,
                         p_instr2,
                         p_innum1,
                         p_innum2,
                         p_outstr1,
                         p_outstr2,
                         p_outnum1,
                         p_outnum2);
      ELSE
        P_OPENRECLAMACION(p_name,
                          p_numsession,
                          p_instr1,
                          p_instr2,
                          p_innum1,
                          p_innum2,
                          p_outstr1,
                          p_outstr2,
                          p_outnum1,
                          p_outnum2);
      END IF;
    ELSIF upper(p_name) = 'CLOSERECLAMACION' THEN
      p_usuario_fono; -- llama procedure para asignar el usuario a la variable vUsuario
      IF vUSUARIO = 'KIOSKO' THEN
        P_CLOSE_PRECERTIFICACION(p_name,
                                 p_numsession,
                                 p_instr1,
                                 p_instr2,
                                 p_innum1,
                                 p_innum2,
                                 p_outstr1,
                                 p_outstr2,
                                 p_outnum1,
                                 p_outnum2);
      ELSE
        P_CLOSERECLAMACION(p_name,
                           p_numsession,
                           p_instr1,
                           p_instr2,
                           p_innum1,
                           p_innum2,
                           p_outstr1,
                           p_outstr2,
                           p_outnum1,
                           p_outnum2);
      END IF;
    ELSIF upper(p_name) = 'DELETECOBERTURA' THEN
      P_DELETECOBERTURA(p_name,
                          p_numsession,
                          p_instr1,
                          p_instr2,
                          p_innum1,
                          p_innum2,
                          p_outstr1,
                          p_outstr2,
                          p_outnum1,
                          p_outnum2);
    ELSIF upper(p_name) = 'DELETERECLAMACION' THEN
      P_DELETERECLAMACION(p_name,
                          p_numsession,
                          p_instr1,
                          p_instr2,
                          p_innum1,
                          p_innum2,
                          p_outstr1,
                          p_outstr2,
                          p_outnum1,
                          p_outnum2);
    ELSIF upper(p_name) = 'RESUMENDIA' THEN
      P_RESUMENRECLAMACION(p_name,
                           p_numsession,
                           p_instr1,
                           p_instr2,
                           p_innum1,
                           p_innum2,
                           p_outstr1,
                           p_outstr2,
                           p_outnum1,
                           p_outnum2);
    END IF;
  END;
  -- ******************************************************************** --
  -- TP Enfoco 01/10/2019
  PROCEDURE P_CREAR_INFOX_SESSION(P_ANO         IN NUMBER,
                                  P_COMPANIA    IN NUMBER,
                                  P_RAMO        IN NUMBER,
                                  P_RECLAMACION IN NUMBER,
                                  P_NUMSESSION  OUT NUMBER) IS

    vMAQUINA    VARCHAR2(30);
    vRECLAMANTE NUMBER;
    vASE_USO    NUMBER;
    vCOMPANIA   NUMBER;
    vRAMO       NUMBER;
    vSEC_POL    NUMBER;
    vPLAN       NUMBER;
    vTIP_REC    VARCHAR2(50);
    vTIP_SER    NUMBER;
    vFEC_APE    DATE;
    vNUM_PLA    NUMBER;
    vDEP_USO    NUMBER;
    vUSU_ING    VARCHAR2(50);
    vPIN        NUMBER;

  cursor c_seqsession is
  select seqsession.nextval from sys.dual;

    CURSOR C_MAQUINA IS
      SELECT SUBSTR(MACHINE, 1, 30)
        FROM V$SESSION
       WHERE USERNAME = USER
         AND AUDSID = SYS_CONTEXT('USERENV', 'SESSIONID');

    CURSOR C_DATOS IS
      SELECT RECLAMANTE,
             ASE_USO,
             COMPANIA,
             RAMO,
             SEC_POL,
             PLAN,
             TIP_REC,
             TIP_SER,
             FEC_APE,
             NUM_PLA,
             DEP_USO,
             USU_ING
        FROM RECLAMACION
       WHERE ANO = P_ANO
         AND COMPANIA = p_COMPANIA
         AND RAMO = P_RAMO
         AND SECUENCIAL = P_RECLAMACION
         AND ESTATUS IN (V_122, V_83);

    CURSOR C_PIN(pTIP_AFI VARCHAR2, pAFILIADO NUMBER) IS
      SELECT PIN
        FROM FONOS_PIN_AFILIADO
       WHERE TIP_AFI = pTIP_AFI
         AND AFILIADO = pAFILIADO;

  BEGIN

    OPEN C_DATOS;
    FETCH C_DATOS
      INTO vRECLAMANTE,
           vASE_USO,
           vCOMPANIA,
           vRAMO,
           vSEC_POL,
           vPLAN,
           vTIP_REC,
           vTIP_SER,
           vFEC_APE,
           vNUM_PLA,
           vDEP_USO,
           vUSU_ING;
    IF C_DATOS%FOUND THEN
      --
      OPEN C_MAQUINA;
      FETCH C_MAQUINA
        INTO vMAQUINA;
      CLOSE C_MAQUINA;
      --
      OPEN C_PIN(vTIP_REC, vRECLAMANTE);
      FETCH C_PIN
        INTO vPIN;
      CLOSE C_PIN;
      --
      p_NUMSESSION := SEQSESSION.NEXTVAL;

      INSERT INTO INFOX_SESSION
        (NUMSESSION,
         INICIO,
         MAQUINA,
         AFILIADO,
         ASEGURADO,
         RECLAMACION,
         COMPANIA,
         RAMO,
         SECUENCIAL,
         PLAN,
         TIP_REC,
         TIP_SER,
         PIN,
         SEC_REC,
         FEC_APE,
         ANO_REC,
         ASE_CARNET,
         DEPENDIENTE,
         USUARIO)
      VALUES
        (p_NUMSESSION,
         SYSDATE,
         vMAQUINA,
         VRECLAMANTE,
         vASE_USO,
         P_RECLAMACION,
         vCOMPANIA,
         vRAMO,
         vSEC_POL,
         vPLAN,
         vTIP_REC,
         vTIP_SER,
         vPIN,
         P_RECLAMACION,
         vFEC_APE,
         P_ANO,
         vNUM_PLA,
         vDEP_USO,
         vUSU_ING);
      --
    END IF;
    CLOSE C_DATOS;

    COMMIT;
  END;
  -- ******************************************************************** --
END pkg_infox_htpa;