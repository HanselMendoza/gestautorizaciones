--------------------------------------------------------
--  DDL for Procedure P_VALIDATEASEGURADO
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_VALIDATEASEGURADO" (
    p_numsession IN NUMBER,
    p_instr1     IN VARCHAR2,
    p_outnum1    OUT NUMBER,
    p_outnum2    OUT NUMBER
) IS

    /* @% Verificar Asegurado  */
    /* Nombre de la Funcion :  Validar Asegurado */
    /* Descripcion : Valida que el Asegurado sea valido */
    /* Descripcion : Valida que el Asegurado sea valido y actualia :*/
    /* code=1 si es valido y code=2 si no es valido, ademas de completar los  */
    /* datos de la poliza y asegurado  */
    fecha_dia                DATE; /* Variable que almacena la Fecha del Dia. */
    dummy                    VARCHAR2(1);
    fonos_row                infox_session%rowtype;
    cod_ase                  NUMBER(11);
    cod_dep                  NUMBER(3);
    var_code                 NUMBER(1) := 1;
    vtip_ase                 VARCHAR2(10);
    v_pss                    NUMBER;
    v_error_handler          VARCHAR2(500);
    var_deducible_1          NUMBER;
    v_acum_rec_g             NUMBER;
    v_valida_limite          NUMBER;
    v_reserva                NUMBER;
    v_var_ind_ded_1          VARCHAR2(10) := 'S';
    var_fec_ini              poliza.fec_ini%TYPE;
    vafiliado_sal            asegurado.codigo%TYPE;
      --
    v_datos_asegurados       VARCHAR2(20);
      --
    v_secuencial_precert     NUMBER;
    v_deducible_mirex        NUMBER;
      --
    CURSOR b IS
    SELECT
        tip_rec,
        afiliado
    FROM
        infox_session
    WHERE
        numsession = p_numsession;
      --
    var1                     b%rowtype;
      --
    CURSOR f IS
    SELECT
        tip_n_med
    FROM
        no_medico
    WHERE
        codigo = var1.afiliado;
      --
    var2                     f%rowtype;
      --
    CURSOR plan_medicina (
        p_compania   NUMBER,
        p_ramo       NUMBER,
        p_secuencial NUMBER,
        p_plan       NUMBER
    ) IS
    SELECT
        '1'
    FROM
        pol_c_sal a
    WHERE
            a.compania = p_compania
        AND a.ramo = p_ramo
        AND a.secuencial = p_secuencial
        AND a.plan = p_plan
        AND a.cobertura = pkg_const.c_medicina_ambulatoria
        AND a.servicio = pkg_const.c_ser_ambulatorio
        AND a.estatus = pkg_const.e_pol_c_sal_vigente;
      ------------------------------------------------------
      --------- AGREGADO PARA BUSCAR EL DEDUCIBLE PRIMERO -- agregado por Leonardo febrero 2019
      ------------------------------------------------------
    CURSOR c IS
    SELECT
        poliza15.fec_ini
    FROM
        poliza poliza15
    WHERE
            poliza15.compania = fonos_row.compania
        AND poliza15.ramo = fonos_row.ramo
        AND poliza15.secuencial = fonos_row.secuencial
        AND poliza15.fec_ver = (
            SELECT
                MAX(fec_ver)
            FROM
                poliza poliza2
            WHERE
                    poliza2.compania = poliza15.compania
                AND poliza2.ramo = poliza15.ramo
                AND poliza2.secuencial = poliza15.secuencial
                      --AND TRUNC(POLIZA2.FEC_VER) <= FECHA_DIA);
                AND poliza2.fec_ver < trunc(fecha_dia) + 1
        );

      --------------------------------------------------------------------------------------------------
      --- CURSOR QUE BUSCA LOS PLANES DE UN AFILIADO, PARA UTILIZARLO EN CASO DE EL PLAN INTERNACIONAL
      --- AUN TENGA DEDUCIBLE PENDIENTE. -- agregado por Leonardo febrero 2019
      --------------------------------------------------------------------------------------------------
    CURSOR c_busca_plan_alternativo_ase IS
    SELECT
        ramo,
        secuencial,
        plan
    FROM
        ase_pol02_v
    WHERE
            asegurado = cod_ase
        AND estatus = pkg_const.e_ase_pol_vigente -- VIGENTE
        AND plan != to_number(fonos_row.plan);

    CURSOR c_busca_plan_alternativo_dep IS
    SELECT
        ramo,
        secuencial,
        plan
    FROM
        dep_pol02_v
    WHERE
            asegurado = cod_ase
        AND dependiente = nvl(cod_dep, 0)
        AND estatus = pkg_const.e_dep_pol_vigente -- VIGENTE
        AND plan != to_number(fonos_row.plan);

    --Miguel A. Carrion 29/06/2020
    CURSOR c_busca_nss_ase IS
    SELECT
        nss
    FROM
        asegurado a
    WHERE
        a.codigo = cod_ase;

    CURSOR c_busca_nss_dep IS
    SELECT
        nss
    FROM
        dependiente
    WHERE
            asegurado = cod_ase
        AND secuencia = nvl(cod_dep, 0);

    v_ramo_alternativo       poliza.ramo%TYPE;
    v_secuencial_alternativo poliza.secuencial%TYPE;
    v_plan_alternativo       plan.codigo%TYPE;
    v_carnet                 VARCHAR(20);
BEGIN
    fecha_dia := trunc(sysdate);
    OPEN b;
    FETCH b INTO var1;
    IF b%found THEN
        IF var1.tip_rec = 'NO_MEDICO' THEN
            OPEN f;
            FETCH f INTO var2;
            IF f%found THEN
                v_pss := var2.tip_n_med;
            END IF;
            CLOSE f;
        ELSE
            v_pss := 0;
        END IF;
    ELSE
        v_pss := 0;
    END IF;

    CLOSE b;
      --
     --Nueva forma de buscar si el canet existe o si esta activo.

    dbaper.p_busca_afiliado_num_plas(p_instr1, cod_ase, cod_dep, vtip_ase, var_code);

         ---Proceso para cancelar los reclamos Transitorio de un afiliado ante de realizar el reclamo

        --@ENFOCO Jose De Leon
    BEGIN
        dbaper.p_canc_statu_ini_afiliado(p_instr1);
    END;
      -- ****************************************************

    IF nvl(cod_dep, 0) = 0 THEN
        vtip_ase := 'ASEGURADO';
          --
    ELSE
        vtip_ase := 'DEPENDIENT';
          --
    END IF;
        --

      -- ****************************************************
    IF var_code = 0 THEN
        dbaper.valida_afiliado_servicio(vtip_ase, v_pss, cod_ase, cod_dep, '',
                                       fonos_row.compania, fonos_row.ramo, fonos_row.secuencial, fonos_row.plan, fonos_row.categoria,
                                       fonos_row.nom_ase, fonos_row.fec_nac, fonos_row.fec_ing, fonos_row.sexo, fonos_row.est_civ,
                                       var_code);

        dbms_output.put_line('VAR_CODE:  ' || var_code);
          --

        --
        ---------------------------------------------------------------------------------
        ----- //////// busca deducible primero -- agregado por Leonardo febrero 2019
        ---------------------------------------------------------------------------------
        OPEN c;
        FETCH c INTO var_fec_ini;
        CLOSE c;
        --
        dbms_output.put_line('vafiliado_sal:  ' || vafiliado_sal);

        /****vafiliado_sal := DBAPER.PAQ_SYNC_RECLAMACION.F_BUSCA_ASEGURADO(COD_ASE,
                                                                       COD_DEP,
                                                                       FONOS_ROW.COMPANIA,
                                                                       FONOS_ROW.RAMO,
                                                                       FONOS_ROW.SECUENCIAL,
                                                                       vTIP_ASE);*******/

        dbms_output.put_line('vafiliado_sal:  ' || vafiliado_sal);
        v_error_handler := dbaper.paq_reclamacion_si.f_obt_datos_ded(1, NULL, NULL, NULL, NULL,
                                                                    NULL, NULL, NULL, fonos_row.ramo, fonos_row.compania,
                                                                    to_char(sysdate, 'YYYY'), 'N', 'N', v_var_ind_ded_1, fonos_row.secuencial,
                                                                    fonos_row.plan, vafiliado_sal, vtip_ase, fecha_dia, 'L',
                                                                    'P', NULL, NULL, NULL, NULL,
                                                                    pkg_const.c_ser_ambulatorio, NULL, 'S', NULL, NULL,
                                                                    'N', NULL, var_deducible_1, fonos_row.mon_rec, v_acum_rec_g,
                                                                    fonos_row.mon_rec, fonos_row.mon_rec, v_reserva, v_valida_limite,
                                                                    0);

        dbms_output.put_line('v_error_handler:  ' || v_error_handler);

        ---------------------------------------------------------------------------------
        ----- //////// busca deducible primero -- agregado por Leonardo febrero 2019
        ---------------------------------------------------------------------------------
        v_deducible_mirex := 0;
        v_deducible_mirex := var_deducible_1;
        ---
        v_ramo_alternativo := NULL;
        v_secuencial_alternativo := NULL;
        v_plan_alternativo := NULL;
        ---
        IF v_deducible_mirex > 0 THEN
            IF nvl(cod_dep, 0) = 0 THEN
                OPEN c_busca_plan_alternativo_ase;
                FETCH c_busca_plan_alternativo_ase INTO
                    v_ramo_alternativo,
                    v_secuencial_alternativo,
                    v_plan_alternativo;
                CLOSE c_busca_plan_alternativo_ase;
            ELSE
                OPEN c_busca_plan_alternativo_dep;
                FETCH c_busca_plan_alternativo_dep INTO
                    v_ramo_alternativo,
                    v_secuencial_alternativo,
                    v_plan_alternativo;
                CLOSE c_busca_plan_alternativo_dep;
            END IF;
        END IF;
        ---
        IF v_ramo_alternativo IS NOT NULL THEN
            fonos_row.ramo := v_ramo_alternativo;
            fonos_row.secuencial := v_secuencial_alternativo;
            fonos_row.plan := v_plan_alternativo;
            v_deducible_mirex := 0;
        END IF;

    ELSE
        p_outnum1 := var_code;
    END IF;
      --
    UPDATE infox_session
    SET
        code = var_code,
        compania = fonos_row.compania,
        ramo = fonos_row.ramo,
        secuencial = fonos_row.secuencial,
        plan = fonos_row.plan,
        sexo = fonos_row.sexo,
        fec_ing = fonos_row.fec_ing,
        fec_nac = fonos_row.fec_nac,
        est_civ = fonos_row.est_civ,
        categoria = fonos_row.categoria,
        nom_ase = fonos_row.nom_ase,
        asegurado = cod_ase,
        dependiente = cod_dep,
        ase_carnet = p_instr1
    WHERE
        numsession = p_numsession;
      --
       --
    p_outnum1 := var_code;
      --
      --
    OPEN plan_medicina(fonos_row.compania, fonos_row.ramo, fonos_row.secuencial, fonos_row.plan);

    FETCH plan_medicina INTO dummy;
      --
    IF plan_medicina%found THEN
        p_outnum2 := fonos_row.plan;
    ELSE
        p_outnum2 := pkg_const.c_plan_basico;
    END IF;

    CLOSE plan_medicina;
      --

END;
