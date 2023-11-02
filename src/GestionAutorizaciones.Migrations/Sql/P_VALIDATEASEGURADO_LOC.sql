--------------------------------------------------------
--  DDL for Procedure P_VALIDATEASEGURADO_LOC
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_VALIDATEASEGURADO_LOC" (
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

    dummy     VARCHAR2(1);
    fonos_row infox_session%rowtype;
    cod_ase   NUMBER(11);
    cod_dep   NUMBER(3);
    var_code  NUMBER(1) := 1;
    vtip_ase  VARCHAR2(10);
    v_pss     NUMBER;
    v_carnet  VARCHAR(20);
      --

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
    var1      b%rowtype;
      --
    CURSOR f IS
    SELECT
        tip_n_med
    FROM
        no_medico
    WHERE
        codigo = var1.afiliado;
      --
    var2      f%rowtype;
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
        AND a.cobertura = pkg_const.C_MEDICINA_AMBULATORIA
        AND a.servicio = pkg_const.C_SER_AMBULATORIO
        AND a.estatus = pkg_const.E_POL_C_SAL_VIGENTE;

BEGIN
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
      -- Proceso que Busca los datos del afiliado por el Numero de Plastico
      -- GMa�on 14/09/2010

    dbaper.p_busca_afiliado_num_plas(p_instr1, cod_ase, cod_dep, vtip_ase, var_code);



         ---Proceso para cancelar los reclamos Transitorio de un afiliado ante de realizar el reclamo

        --@ENFOCO Jose De Leon
    BEGIN
        dbaper.p_canc_statu_ini_afiliado(p_instr1);
    END;
    IF var_code = 0 THEN
        dbaper.valida_afiliado_servicio_loc(vtip_ase, v_pss, cod_ase, cod_dep, '',
                                           fonos_row.compania, fonos_row.ramo, fonos_row.secuencial, fonos_row.plan, fonos_row.categoria,
                                           fonos_row.nom_ase, fonos_row.fec_nac, fonos_row.fec_ing, fonos_row.sexo, fonos_row.est_civ,
                                           var_code);
          --

        --
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
    p_outnum1 := var_code;
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
    /*EXCEPTION
      WHEN OTHERS THEN
        VAR_CODE  := 4;
        P_OUTNUM1 := VAR_CODE;*/
END;
