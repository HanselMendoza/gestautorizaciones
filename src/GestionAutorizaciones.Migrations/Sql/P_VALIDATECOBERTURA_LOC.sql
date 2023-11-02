--------------------------------------------------------
--  DDL for Procedure P_VALIDATECOBERTURA_LOC
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_VALIDATECOBERTURA_LOC" (
    p_numsession IN NUMBER,
    p_instr1     IN VARCHAR2,
    p_instr2     IN VARCHAR2,
    p_innum1     IN NUMBER,
    p_innum2     IN NUMBER,
    p_outstr1    OUT VARCHAR2,
    p_outstr2    OUT VARCHAR2,
    p_outnum1    OUT NUMBER,
    p_outnum2    OUT NUMBER
) IS
BEGIN
    /* @% Verificar Disponibilidad de Cobertura */
    /* Descripcion : Valida que el Afiliado  pueda ofrecer la cobertura y que el asegurado*/
    /*               pueda recibir la cobertura. */
    DECLARE
        vusuario                  VARCHAR2(15) := nvl(dbaper.f_busca_usu_registra_canales(user), 'FONOSALUD');
        dummy                     VARCHAR2(1);
        error                     CHAR(1);
        error1                    BOOLEAN; /*  Se utiliza igual que ERROR, pero es enviada en algunos casos que la funcion devuelve boolean */
        var_code                  NUMBER(2) := 1;
        fonos_row                 infox_session%rowtype;
        ser_sal_row               ser_sal%rowtype;
        tip_c_sal_row             tip_c_sal%rowtype;
        cob_sal_row               cob_sal%rowtype;
        no_m_cob_row              no_m_cob%rowtype;
        des_tip_n_med             tipo_no_medico.descripcion%TYPE;
        cod_ase                   NUMBER(11);
        cod_dep                   NUMBER(3);
        var_tip_ser2              ser_sal.codigo%TYPE;
        fecha_dia                 DATE;
        por_coa                   pol_p_ser.por_coa%TYPE;
        pla_stc_row               pla_stc%rowtype;
        var_estatus_can           reclamacion.estatus%TYPE := 183;
        var_tip_a_uso             reclamacion.tip_a_uso%TYPE;
        var_fec_ini               poliza.fec_ini%TYPE;
        var_fec_fin               poliza.fec_fin%TYPE;
        t_fec_ini                 poliza.fec_ini%TYPE;
        t_fec_fin                 poliza.fec_fin%TYPE;
        dsp_cob_lab               NUMBER;
        dsp_frec_tip_cob          NUMBER;
        dsp_frec_acum             NUMBER;
        dsp_mon_pag_acum          NUMBER;
        sec_reclamacion           reclamacion.secuencial%TYPE;
        monto_contratado          VARCHAR(1);
      /* Parametro para saber si la cobertura esta contratada con  */
      /* el reclamante o con la poliza (ej. habitacion y medicina) */
        monto_laboratorio         NUMBER(11, 2);
        var_categoria             VARCHAR2(40);
        p_dsp_categoria           pla_stc.categoria%TYPE;
        p_dsp_est_civ             pla_stc.est_civ%TYPE;
        limite_laboratorio        lim_c_rec.mon_max%TYPE;
        p_mon_exe                 lim_c_rec.mon_e_coa%TYPE;
        p_uni_t_exe               lim_c_rec.uni_tie_e%TYPE;
        p_uni_t_max               lim_c_rec.uni_tie_m%TYPE;
        p_ran_exe                 lim_c_rec.ran_u_exc%TYPE;
        p_por_coa                 lim_c_rec.por_coa%TYPE;
        p_mon_acum                NUMBER(14, 2);
        ori_flag                  VARCHAR2(1);
        v_inser                   NUMBER(2);
        v_intip                   NUMBER(3);
        v_incob                   VARCHAR2(10);
        p_monto_max               NUMBER(11, 2);
        var_frecuencia            pla_stc_row.frecuencia%TYPE;
        var_uni_tie_f             pla_stc_row.uni_tie_f%TYPE;
        var_dsp_frec_acum         dsp_frec_acum%TYPE;
        v_msg                     VARCHAR2(100);
        v_red_plat                NUMBER(3);

      -- Technocons
        mfraude                   VARCHAR(1);
        vmon_max_cob_origen       NUMBER(11, 2);
        v_prov_capitado           NUMBER(1) := 0;
        v_prov_basico             NUMBER;
        v_prov_existe             NUMBER;
        v_nuevo                   VARCHAR2(1);
        m_plan_exception          VARCHAR2(4000);
        m_valida_plan             VARCHAR2(4000);
      --
        p_ran_u_exc               lim_c_rec.ran_u_exc%TYPE;
        p_ran_u_max               lim_c_rec.ran_u_exc%TYPE;

      --<jdeveaux 18may2016>
      --Variables para capturar los datos de la poliza original de plan voluntario cambia a la poliza del plan basico
        v_plan_ori                NUMBER(3);
        v_compania_ori            NUMBER(2);
        v_ramo_ori                NUMBER(2);
        v_sec_ori                 NUMBER(7);
      --</jdeveaux>
        vestudio_repeticion       VARCHAR2(1) := 'N';
        v_deducible_mirex         NUMBER := p_innum1;
        v_monpag_devuelve_funcion NUMBER := p_innum2;
        CURSOR c_plan_exception IS
        SELECT
            valparam
        FROM
            tparagen d
        WHERE
            nomparam IN ( 'LIB_PLAN_FONO' )
            AND compania = fonos_row.compania;

        CURSOR c_valida_plan_excento (
            mplan        VARCHAR2,
            m_lista_plan VARCHAR2
        ) IS
        SELECT
            column_value
        FROM
            TABLE ( split(m_lista_plan) )
        WHERE
            column_value = mplan;

        CURSOR a IS
        SELECT
            tip_rec,
            afiliado,
            tip_cob,
            cobertura,
            compania,
            ramo,
            secuencial,
            plan,
            asegurado,
            dependiente,
            sexo,
            fec_ing,
            fec_nac,
            ano_rec,
            sec_rec,
            categoria,
            est_civ,
            mon_rec_afi,
            cat_n_med,
            tip_ser,
            nvl(tiene_excesoporgrupo, 'N') tiene_excesoporgrupo
        FROM
            infox_session
        WHERE
            numsession = p_numsession
        FOR UPDATE;

        CURSOR b IS
        SELECT
            tip_n_med.descripcion
        FROM
            no_medico,
            tipo_no_medico tip_n_med
        WHERE
                no_medico.codigo = fonos_row.afiliado
            AND tip_n_med.codigo = no_medico.tip_n_med;

        CURSOR c IS
        SELECT
            poliza15.fec_ini,
            poliza15.fec_fin
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
                    AND poliza2.fec_ver < trunc(fecha_dia) + 1
            );

        CURSOR d IS
        SELECT
            descripcion
        FROM
            categoria_asegurado
        WHERE
            codigo = fonos_row.categoria;

        CURSOR c_cobertura IS
        SELECT
            '1'
        FROM
            cob_sal
        WHERE
            codigo = to_number(fonos_row.cobertura);

      -- Technocons * Victor Acevedo
        CURSOR c_fraude IS
        SELECT
            fraude
        FROM
            motivo_ase_dep
        WHERE
                asegurado = cod_ase
            AND dependiente = nvl(cod_dep, 0)
            AND fraude = pkg_const.c_si;

      --TP 09/11/2018 Enfoco
        CURSOR cat_medico (
            vreclamante NUMBER
        ) IS
        SELECT
            codigo
        FROM
            medico a
        WHERE
                codigo = vreclamante
            AND EXISTS (
                SELECT
                    1
                FROM
                    med_esp_v b
                WHERE
                        a.codigo = b.medico
                    AND b.especialidad = pkg_const.c_esp_odontologia
            );

        CURSOR cat_n_med (
            vreclamante NUMBER
        ) IS
        SELECT
            codigo
        FROM
            no_medico
        WHERE
                codigo = vreclamante
            AND tip_n_med = pkg_const.c_tiponmed_odontologia;

        v_cat                     NUMBER;

      ---Enfoco mcarrion 12/02/2019
        CURSOR cur_prov_capitado IS
        SELECT
            valor_capita,
            afiliado
        FROM
            poliza_provedor p,
            no_medico       n
        WHERE
                p.compania = fonos_row.compania
            AND p.ramo = fonos_row.ramo
            AND p.secuencial = fonos_row.secuencial
            AND p.servicio = fonos_row.tip_ser
            AND p.plan = fonos_row.plan
            AND n.codigo = p.afiliado
            AND n.valor_capita = pkg_const.c_activo
            AND p.estatus = pkg_const.e_pol_pro_vigente
            AND p.fec_ver = (
                SELECT
                    MAX(fec_ver)
                FROM
                    poliza_provedor a
                WHERE
                        a.compania = p.compania
                    AND a.ramo = p.ramo
                    AND a.secuencial = p.secuencial
                    AND a.plan = p.plan
            );

        CURSOR cap_basico (
            p_proveedor NUMBER
        ) IS
        SELECT
            1
        FROM
            plan_afiliado
        WHERE
                plan = pkg_const.c_plan_basico --*--
            AND afiliado = p_proveedor
            AND servicio = pkg_const.c_serv_odontologicos --*--
            AND tip_afi IN ( pkg_const.c_no_medico, pkg_const.c_medico );

        CURSOR nuevo (
            vreclamante NUMBER
        ) IS
        SELECT
            'S'
        FROM
            plan_dental_nuevo p
        WHERE
                p.tip_afi = pkg_const.c_no_medico
            AND p.afiliado = vreclamante
            AND p.nuevo = pkg_const.c_si;

      /* Rutina Principal */
    BEGIN
        fecha_dia := to_date(to_char(sysdate, 'dd/mm/yyyy'), 'dd/mm/yyyy');
        OPEN a;
        FETCH a INTO
            fonos_row.tip_rec,
            fonos_row.afiliado,
            fonos_row.tip_cob,
            fonos_row.cobertura,
            fonos_row.compania,
            fonos_row.ramo,
            fonos_row.secuencial,
            fonos_row.plan,
            fonos_row.asegurado,
            fonos_row.dependiente,
            fonos_row.sexo,
            fonos_row.fec_ing,
            fonos_row.fec_nac,
            fonos_row.ano_rec,
            fonos_row.sec_rec,
            fonos_row.categoria,
            fonos_row.est_civ,
            fonos_row.mon_rec_afi,
            fonos_row.cat_n_med,
            fonos_row.tip_ser,
            fonos_row.tiene_excesoporgrupo;

        IF a%found THEN
            OPEN d;
            FETCH d INTO var_categoria;
            CLOSE d;
        --
            cod_ase := to_number(fonos_row.asegurado);
            cod_dep := to_number(fonos_row.dependiente);
        --
            IF nvl(cod_dep, 0) = 0 THEN
                var_tip_a_uso := 'ASEGURADO';
            ELSE
                var_tip_a_uso := 'DEPENDIENT';
            END IF;
        --
            IF fonos_row.tip_rec = 'NO_MEDICO' THEN
                OPEN b;
                FETCH b INTO des_tip_n_med;
                CLOSE b;
            ELSE
                des_tip_n_med := fonos_row.tip_rec;
            END IF;
        --
            OPEN c;
            FETCH c INTO
                var_fec_ini,
                var_fec_fin;
            CLOSE c;
        --
        /*codigo nuevo*/
            v_inser := to_number(substr(p_instr1, 1, 2));
            v_intip := to_number(substr(p_instr1, 3, 2));
            v_incob := substr(p_instr1, 5, 10);
        --

            IF v_intip = 6 THEN
                v_inser := 8; --TP 09/11/2018
          --<00062> jdeveaux 27nov2017 Se valida la red dental del afiliado para determinar servicio
          /*V_RED_PLAT := DBAPER.F_VALIDA_RED_DENTAL_PLATINUM(FONOS_ROW.COMPANIA, FONOS_ROW.RAMO, FONOS_ROW.SECUENCIAL, FONOS_ROW.PLAN, V_MSG);
          IF  V_RED_PLAT = 8 THEN
               V_INSER :=  V_RED_PLAT;
          ELSE
               V_INSER := 1;
          END IF;*/
          --</00062>
            ELSIF
                v_intip > 7
                AND v_intip <> 76
            THEN
                v_inser := 3;
            ELSE
                v_inser := 1;
            END IF;

        --TP 09/11/2018 Enfoco
            IF fonos_row.tip_rec = 'MEDICO' THEN
                OPEN cat_medico(fonos_row.afiliado);
                FETCH cat_medico INTO v_cat;
                IF cat_medico%found THEN
                    v_inser := 8;
                END IF;
                CLOSE cat_medico;
            ELSE
                OPEN cat_n_med(fonos_row.afiliado);
                FETCH cat_n_med INTO v_cat;
                IF cat_n_med%found THEN
                    v_inser := 8;
                END IF;
                CLOSE cat_n_med;
            END IF;
        --TP 09/11/2018 Enfoco

        --SI AUN NO SE HA GENERADO UNA RECLAMACION TOMA EL SERVICIO DEL VALOR DIGITADO--
        --EN CASO CONTRARIO TOMA EL SERVICIO DE LA RECLAMACION YA INSERTADA--
            IF ( nvl(fonos_row.sec_rec, 0) = 0 ) THEN
                fonos_row.tip_ser := v_inser;
            END IF;

            fonos_row.tip_cob := v_intip;
            fonos_row.cobertura := v_incob;
            var_tip_ser2 := fonos_row.tip_ser;
        --
        --Enfoco mcarrion 12/02/2019
            IF
                fonos_row.tip_rec = 'NO_MEDICO'
                AND fonos_row.tip_ser = 8
            THEN
                OPEN cur_prov_capitado;
                FETCH cur_prov_capitado INTO
                    v_prov_capitado,
                    v_prov_basico;
                CLOSE cur_prov_capitado;
                OPEN cap_basico(v_prov_basico);
                FETCH cap_basico INTO v_prov_existe;
                CLOSE cap_basico;
                OPEN nuevo(fonos_row.afiliado);
                FETCH nuevo INTO v_nuevo;
                CLOSE nuevo;
                IF
                    v_prov_capitado = 1
                    AND nvl(v_prov_existe, 0) = 0
                    AND nvl(v_nuevo, 'N') = 'N'
                THEN
            --
                    var_code := 2; --MSG_ALERT('Afiliado tiene un plan capitado, no debe pasar reclamaciones.','E', TRUE);
            --
                END IF;

            END IF;
        ---Enfoco mcarrion 12/02/2019

        /*PROCEDIMIENTO PARA PROBAR
        FONOS_ROW.COBERTURA := P_INSTR1;
          FONOS_ROW.TIP_COB   := 5;
          FONOS_ROW.TIP_SER   := 1;*/
            IF nvl(cod_ase, 0) = 0 THEN
                var_code := 1;
            END IF;
        --  IF VAR_CODE IS NULL OR VAR_CODE <> 2 THEN
            IF nvl(cod_ase, 0) <> 0 THEN
                OPEN c_cobertura;
                FETCH c_cobertura INTO dummy;
                IF c_cobertura%notfound THEN
                    error := '1';
                END IF;
                CLOSE c_cobertura;
                IF error IS NULL THEN
                    error := f_buscar_datos_cobertura(fonos_row, var_tip_ser2, fonos_row.tip_cob, ser_sal_row.descripcion, tip_c_sal_row.
                    descripcion,
                                                     cob_sal_row.descripcion, no_m_cob_row.limite, no_m_cob_row.por_des);

            --<jdeveaux 18may2016>
            /*Procedimiento para validar si el prestador de servicios se encuentra en la red del plan basico si no esta en la red de la poliza voluntario.*/
            /*Si se da esta condicion, todas las validaciones posteriores de coberturas deben hacerse bajo la configuracion del plan basico (ramo, secuencial, plan)*/
                    DECLARE
                        red_voluntario     BOOLEAN;
                        red_excepcion_odon BOOLEAN;
                        red_pbs            BOOLEAN;
                        v_plan_pbs         NUMBER(3);
                        v_compania_pbs     NUMBER(2);
                        v_ramo_pbs         NUMBER(2);
                        v_sec_pbs          NUMBER(7);
                    BEGIN
              --Se limpian las variables
                        v_plan_pbs := NULL;
                        v_compania_pbs := NULL;
                        v_ramo_pbs := NULL;
                        v_sec_pbs := NULL;
              --
              --Solo debe funcionar para las polizas voluntarias
                        IF fonos_row.ramo = pkg_const.c_ramo_salud_local THEN
                --Valida si el proveedor pertenece a la red del plan voluntario
                            red_voluntario := paq_matriz_validaciones.validar_plan_afiliado(fonos_row.plan, fonos_row.tip_ser, fonos_row.
                            tip_rec, fonos_row.afiliado);

                --MCARRION 26/06/2019
                            red_excepcion_odon := dbaper.excepcion_poliza_odon(fonos_row.compania, fonos_row.ramo, fonos_row.secuencial,
                            fonos_row.tip_ser);

                            IF
                                NOT ( red_voluntario )
                                AND NOT ( red_excepcion_odon )
                            THEN

                  --DBMS_OUTPUT.PUT_LINE('RED_VOLUNTARIO 2 ');
                  --Busca los datos de la poliza del plan basico
                                dbaper.poliza_plan_basico(v_compania_pbs, v_ramo_pbs, v_sec_pbs, v_plan_pbs);
                  --Valida si el proveedor pertenece a la red del plan basico
                                red_pbs := paq_matriz_validaciones.validar_plan_afiliado(v_plan_pbs, fonos_row.tip_ser, fonos_row.tip_rec,
                                fonos_row.afiliado);

                                IF red_pbs THEN
                    --Guarda en variables los datos originales de la poliza voluntaria
                                    v_plan_ori := fonos_row.plan;
                                    v_compania_ori := fonos_row.compania;
                                    v_ramo_ori := fonos_row.ramo;
                                    v_sec_ori := fonos_row.secuencial;

                    --Cambia los datos de poliza y plan a los del Plan Basico. Esto debe ser restaurado antes de salir de VALIDATECOBERTURA
                                    fonos_row.plan := v_plan_pbs;
                                    fonos_row.compania := v_compania_pbs;
                                    fonos_row.ramo := v_ramo_pbs;
                                    fonos_row.secuencial := v_sec_pbs;
                                END IF;

                            END IF;

                        END IF;

                    END;
            --</jdeveaux>

                    IF error IS NULL THEN
              -- Enfoco - 05/11/2018
                        paq_matriz_validaciones.busca_rangos_cobertura(fonos_row.plan, fonos_row.tip_ser, fonos_row.tip_cob, p_ran_u_exc,
                        p_ran_u_max);
              /* ---------------------------------------------------------------------- */
              /*   Determina Origen de la Cobertura                                      */
              /* ---------------------------------------------------------------------- */
              --
                        OPEN c_plan_exception;
                        FETCH c_plan_exception INTO m_plan_exception;
                        CLOSE c_plan_exception;
                        OPEN c_valida_plan_excento(fonos_row.plan, m_plan_exception);
                        FETCH c_valida_plan_excento INTO m_valida_plan;
                        IF c_valida_plan_excento%notfound THEN
                            IF NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, fonos_row.ramo, fonos_row.
                            secuencial, fonos_row.plan, fonos_row.tip_ser,
                                                                                      fonos_row.tip_cob, fonos_row.cobertura) THEN
                                ori_flag := paq_matriz_validaciones.busca_origen_cob(fonos_row.tip_ser, fonos_row.tip_cob, fonos_row.
                                cobertura, vusuario);

                                IF ori_flag IS NOT NULL THEN
                                    error := '1';
                                END IF;
                                IF error IS NOT NULL THEN
                                    vestudio_repeticion := f_busca_cob_estudio_repeticion(fonos_row.asegurado, fonos_row.dependiente,
                                    fonos_row.compania, fonos_row.ramo, fonos_row.secuencial,
                                                                                         fonos_row.tip_ser, fonos_row.tip_cob, fonos_row.
                                                                                         cobertura, vusuario);

                                    IF nvl(vestudio_repeticion, 'N') = 'S' THEN
                                        error := NULL;
                                    END IF;
                                END IF;

                                IF error IS NULL THEN
                    -- Htorres - 29/09/2019
                    -- Monto m�ximo que se pueda otorgar para esa cobertura por canales
                                    vmon_max_cob_origen := f_busca_origen_cob_mon_max(fonos_row.tip_ser, fonos_row.tip_cob, fonos_row.
                                    cobertura, vusuario);
                                END IF;

                            END IF;
                        END IF;

                        CLOSE c_valida_plan_excento;
                        IF error IS NULL THEN
                /* --------------------------------------------------------------------- */
                /* --------------------------------------------------------------------- */
                /*  Busca Limite de monto por cobertura de salud                         */
                /* --------------------------------------------------------------------- */
                            IF NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, fonos_row.ramo, fonos_row.
                            secuencial, fonos_row.plan, fonos_row.tip_ser,
                                                                                      fonos_row.tip_cob, fonos_row.cobertura) THEN
                  --
                                limite_laboratorio := paq_matriz_validaciones.tip_cob_mon_max(fonos_row.compania, fonos_row.ramo, fonos_row.
                                secuencial, fonos_row.plan, fonos_row.tip_ser,
                                                                                             fonos_row.tip_cob, p_mon_exe, p_uni_t_exe,
                                                                                             p_ran_exe, p_por_coa,
                                                                                             p_uni_t_max);
                  --
                            END IF;
                --
                --P_MON_DED_TIP_COB);
                /* --------------------------------------------------------------------- */
                /* Valida que el Asegurado puede Recibir la Cobertura de Salud.          */
                /* --------------------------------------------------------------------- */
                            error := paq_matriz_validaciones.chk_cobertura_asegurado_fono(true, fonos_row.tip_rec, fonos_row.afiliado,
                            des_tip_n_med, var_tip_a_uso,
                                                                                         cod_ase, cod_dep, fonos_row.compania, fonos_row.
                                                                                         ramo, fonos_row.secuencial,
                                                                                         fonos_row.plan, fonos_row.tip_ser, fonos_row.
                                                                                         tip_cob, fonos_row.cobertura, var_tip_ser2,
                                                                                         fecha_dia, fonos_row.sexo, fonos_row.est_civ,
                                                                                         var_categoria, fonos_row.fec_nac,
                                                                                         por_coa, no_m_cob_row.limite, pla_stc_row.frecuencia,
                                                                                         pla_stc_row.uni_tie_f, pla_stc_row.tie_esp,
                                                                                         pla_stc_row.uni_tie_t, pla_stc_row.mon_max, --A--
                                                                                          pla_stc_row.uni_tie_m, pla_stc_row.sexo, pla_stc_row.
                                                                                         eda_min,
                                                                                         pla_stc_row.eda_max, p_dsp_est_civ, p_dsp_categoria,
                                                                                         monto_contratado, vusuario,
                                                                                         p_por_coa, p_monto_max, --A estaba dos veces--
                                                                                          pla_stc_row.exc_mca, pla_stc_row.mon_ded);

                            IF error IS NULL THEN
                  /*---------------------------------------------------------- */
                  /* Valida que no se este digitando una Reclamacion           */
                  /* que ya fue reclamada por el mismo.                        */
                  /* --------------------------------------------------------- */
                                sec_reclamacion := paq_matriz_validaciones.valida_rec_fecha_null(true, var_estatus_can, fonos_row.ano_rec,
                                fonos_row.compania, v_ramo_ori, -- FONOS_ROW.RAMO,      -- V_RAMO_ORI Reclamaciones Duplicadas (Victor Acevedo)
                                                                                                fonos_row.sec_rec, fonos_row.tip_rec,
                                                                                                fonos_row.afiliado, var_tip_a_uso, cod_ase,
                                                                                                cod_dep, fonos_row.tip_ser, fonos_row.
                                                                                                tip_cob, fonos_row.cobertura, fecha_dia);

                                IF sec_reclamacion IS NOT NULL THEN
                                    error := '1';
                                END IF;
                  --
                                IF error IS NULL THEN
                    /* ---------------------------------------------------------- */
                    /* Valida que no se este digitando una Reclamacion            */
                    /* que ya fue reclamada por otro que participo en la          */
                    /* aplicacion de la Cobertura.                                */
                    /* ---------------------------------------------------------- */
                                    error := paq_matriz_validaciones.valida_rec_c_sal_fec(true, var_estatus_can, fonos_row.ano_rec, fonos_row.
                                    compania, fonos_row.ramo,
                                                                                         fonos_row.sec_rec, fonos_row.tip_rec, fonos_row.
                                                                                         afiliado, var_tip_a_uso, cod_ase,
                                                                                         cod_dep, fonos_row.tip_ser, fonos_row.tip_cob,
                                                                                         fonos_row.cobertura, fecha_dia);

                                    IF error IS NULL THEN
                      /* ---------------------------------------------------------- */
                      /* Valida:                                                    */
                      /* 1-) Tiempo de Espera de la Cobertura                       */
                      /* ---------------------------------------------------------- */
                                        error := paq_matriz_validaciones.validar_tiempo_espera(true, fecha_dia,
                                                                             --VAR_FEC_INI,
                                         fonos_row.fec_ing, pla_stc_row.tie_esp, pla_stc_row.uni_tie_t);

                                        IF error IS NULL OR error = '0' -- Caso # 14282

                                         THEN
                        /* ---------------------------------------------------------- */
                        /* Valida:                                                    */
                        /* 1-) Cobertura No Exceda la Frecuencia de Uso para su       */
                        /*     Tipo de Cobertura.                                     */
                        /* ---------------------------------------------------------- */
                        /* ***** SOLO Aplica para Tipo_Coberturas:LABORATORIOS ****** */
                        /* ***** en Servicios:AMBULATORIO                      ****** */
                        /* ---------------------------------------------------------- */
                                            IF NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, fonos_row.
                                            ramo, fonos_row.secuencial, fonos_row.plan, fonos_row.tip_ser,
                                                                                                      fonos_row.tip_cob, fonos_row.cobertura)
                                                                                                      THEN
                          --
                                                error := paq_matriz_validaciones.validar_frec_tip_cob(true, var_estatus_can, var_tip_a_uso,
                                                cod_ase, cod_dep,
                                                                                                     fonos_row.plan, fonos_row.tip_ser,
                                                                                                     fonos_row.tip_cob, fonos_row.cobertura,
                                                                                                     fecha_dia,
                                                                                                     var_fec_ini, fonos_row.compania,
                                                                                                     fonos_row.ramo, fonos_row.secuencial,
                                                                                                     dsp_cob_lab,
                                                                                                     dsp_frec_tip_cob);
                          --
                                            END IF;
                        --
                                            IF error IS NULL THEN
                          /* ---------------------------------------------------------- */
                          /* Valida que en las Reclamaciones:                           */
                          /* 1-) Cobertura No Exceda la Frecuencia de Uso               */
                          /* 2-) Cobertura No Exceda los Montos Maximo.                 */
                          /* ---------------------------------------------------------- */
                                                IF NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, fonos_row.
                                                ramo, fonos_row.secuencial, fonos_row.plan, fonos_row.tip_ser,
                                                                                                          fonos_row.tip_cob, fonos_row.
                                                                                                          cobertura) THEN
                            --
                                                    error := paq_matriz_validaciones.validar_frec_cobertura(true, var_estatus_can, var_tip_a_uso,
                                                    cod_ase, cod_dep,
                                                                                                           fonos_row.tip_ser, fonos_row.
                                                                                                           tip_cob, fonos_row.cobertura,
                                                                                                           fecha_dia, var_fec_ini,
                                                                                                           fonos_row.fec_ing, pla_stc_row.
                                                                                                           frecuencia, pla_stc_row.uni_tie_f,
                                                                                                           pla_stc_row.tie_esp, pla_stc_row.
                                                                                                           uni_tie_t,
                                                                                                           pla_stc_row.mon_max, pla_stc_row.
                                                                                                           uni_tie_m, fonos_row.compania,
                                                                                                           dsp_frec_acum, dsp_mon_pag_acum,
                                                                                                           fonos_row.plan);
                            --
                                                END IF;
                          --
                                                IF error IS NULL THEN
                            /* --------------------------------------------------- */
                            /* Determina el limite de frecuencia paralelo          */
                            /* por plan por tipo de cobertura                      */
                            /* --------------------------------------------------- */
                                                    IF NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, fonos_row.
                                                    ramo, fonos_row.secuencial, fonos_row.plan, fonos_row.tip_ser,
                                                                                                              fonos_row.tip_cob, fonos_row.
                                                                                                              cobertura) THEN
                              --
                                                        error := paq_matriz_validaciones.validar_frec_tip_cob_fono(p_field_level => true,
                                                        p_var_estatus_can => var_estatus_can, -- Cancelada en la Rec
                                                         p_tip_a_uso => var_tip_a_uso, p_ase_uso => cod_ase, p_dep_uso => cod_dep,
                                                                                                                  p_plan => fonos_row.
                                                                                                                  plan, p_servicio =>
                                                                                                                  fonos_row.tip_ser, p_tip_cob =>
                                                                                                                  fonos_row.tip_cob, p_cobertura =>
                                                                                                                  fonos_row.cobertura,
                                                                                                                  p_fec_ser => fecha_dia,
                                                                                                                  p_fec_ini_pol => var_fec_ini,
                                                                                                                  p_fec_ing => fonos_row.
                                                                                                                  fec_ing, p_frecuencia =>
                                                                                                                  var_frecuencia, p_uni_tie_f =>
                                                                                                                  var_uni_tie_f, p_tie_esp =>
                                                                                                                  pla_stc_row.tie_esp,
                                                                                                                  p_uni_tie_t => pla_stc_row.
                                                                                                                  uni_tie_t, p_mon_max =>
                                                                                                                  pla_stc_row.mon_max,
                                                                                                                  p_uni_tie_m => pla_stc_row.
                                                                                                                  uni_tie_m, p_dsp_frec_acum =>
                                                                                                                  var_dsp_frec_acum);

                              --
                                                    END IF;

                            --
                                                    IF error IS NULL THEN
                              /* ---------------------------------------------------  */
                              /* Determina si el afiliado digita el Monto a Reclamar  */
                              /* para igualar el limite al monto digitado             */
                              /* ---------------------------------------------------  */
                              --VIA FONOSALUD EL AFILIADO NO DIGITA NINGUN MONTO A RECLAMAR--
                              --VIA POS EL AFILIADO DIGITA EL MONTO A RECLAMAR--
                                                        IF nvl(to_number(p_instr2), 0) > 0 THEN
                                                            IF nvl(to_number(p_instr2), 0) < no_m_cob_row.limite THEN
                                                                fonos_row.mon_rec_afi := to_number(p_instr2);
                                                            ELSE
                                                                fonos_row.mon_rec_afi := no_m_cob_row.limite;
                                                            END IF;
                                                        END IF;

                                                        IF
                                                            fonos_row.mon_rec_afi IS NOT NULL
                                                            AND fonos_row.mon_rec_afi <> 0
                                                        THEN
                                                            no_m_cob_row.limite := fonos_row.mon_rec_afi;
                                                        END IF;
                              /*-------------------------------------------------------------- */
                              /* Buscar monto acumulados de reclamaciones en periodo de tiempo,*/
                              /* si tiene monto excento por tipo de cobertura                  */
                              /*-------------------------------------------------------------- */
                                                        p_mon_acum := 0;
                                                        IF
                                                            p_mon_exe IS NOT NULL
                                                            AND p_mon_exe <> 0
                                                        THEN
                                /* -----------------------------------------------------------------------  */
                                /* Obtiene la Fecha Inicial segun la Unidad de Tiempo                       */
                                /* de monto excento para determinar si ha excedido el Uso de la Cobertura.  */
                                /* -----------------------------------------------------------------------  */
                                                            t_fec_ini := paq_matriz_validaciones.determina_fecha_rango(fecha_dia, var_fec_ini,
                                                            NULL, NULL, NULL,
                                                                                                                      p_ran_u_exc, p_mon_exe,
                                                                                                                      nvl(p_uni_t_exe,
                                                                                                                      365));
                                /* ----------------------------------------------------------------------  */
                                /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto excento   */
                                /* para determinar si ha excedido el Uso excento de la Cobertura.          */
                                /* ----------------------------------------------------------------------  */
                                                            t_fec_fin := paq_matriz_validaciones.determina_fecha_rango_fin(fecha_dia,
                                                            var_fec_ini, NULL, NULL, NULL,
                                                                                                                          p_mon_exe, nvl(
                                                                                                                          p_uni_t_exe,
                                                                                                                          365), p_ran_u_exc);
                                /* Si la Fecha Fin es null, entonces sera igual */
                                /* a la Fecha de Servicio.      */
                                                            IF t_fec_fin IS NULL THEN
                                                                t_fec_fin := fecha_dia;
                                                            END IF;
                                                            p_mon_acum := paq_matriz_validaciones.buscar_rec_acumuladas(var_tip_a_uso,
                                                            cod_ase, cod_dep, fecha_dia, fonos_row.compania,
                                                                                                                       fonos_row.ramo,
                                                                                                                       fonos_row.plan,
                                                                                                                       fonos_row.tip_ser,
                                                                                                                       fonos_row.tip_cob,
                                                                                                                       var_estatus_can,
                                                                                                                       t_fec_ini, t_fec_fin);

                                                        END IF;
                              /* ------------------------------------------------------------- */
                              /* Procedure que llama los program unit que realizan el          */
                              /* Calculo de la Reserva.                                        */
                              /* ------------------------------------------------------------- */
                                                        p_calcular_reserva(no_m_cob_row.limite, no_m_cob_row.por_des, por_coa, fonos_row.
                                                        mon_pag, fonos_row.mon_ded,
                                                                          p_mon_exe, p_mon_acum);

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
                                                        monto_laboratorio := 0;
                              --
                                                        IF
                                                            limite_laboratorio IS NOT NULL
                                                            AND limite_laboratorio <> 0
                                                        THEN
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
                                                            t_fec_ini := paq_matriz_validaciones.determina_fecha_rango(fecha_dia, var_fec_ini,
                                                            NULL, NULL, NULL,
                                                                                                                      p_ran_u_exc, limite_laboratorio,
                                                                                                                      nvl(p_uni_t_max,
                                                                                                                      365));
                                /* ----------------------------------------------------------------------  */
                                /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto maximo  */
                                /* para determinar si ha excedido el Uso maximo de la Cobertura.          */
                                /* ----------------------------------------------------------------------  */
                                                            t_fec_fin := paq_matriz_validaciones.determina_fecha_rango_fin(fecha_dia,
                                                            var_fec_ini, NULL, NULL, NULL,
                                                                                                                          limite_laboratorio,
                                                                                                                          nvl(p_uni_t_max,
                                                                                                                          365), p_ran_u_exc);
                                /* Si la Fecha Fin es null, entonces sera igual
                                */
                                /* a la Fecha de Servicio.     */
                                                            IF t_fec_fin IS NULL THEN
                                                                t_fec_fin := fecha_dia;
                                                            END IF;
                                --
                                                            monto_laboratorio := paq_matriz_validaciones.validar_lab_rayos(var_tip_a_uso,
                                                            cod_ase, cod_dep, fecha_dia, fonos_row.compania,
                                                                                                                          fonos_row.ramo,
                                                                                                                          fonos_row.secuencial,
                                                                                                                          fonos_row.plan,
                                                                                                                          fonos_row.tip_ser,
                                                                                                                          fonos_row.tip_cob,
                                                                                                                          fonos_row.cobertura,
                                                                                                                          var_estatus_can,
                                                                                                                          t_fec_ini, t_fec_fin);
                                --
                                                            monto_laboratorio := monto_laboratorio + fonos_row.mon_pag;
                                                            IF monto_laboratorio > limite_laboratorio THEN
                                                                error := '1';
                                                            END IF;
                                --
                                                        END IF; /*END LIMITE_LABORATORIO IS NOT NULL*/

                              -- Htorres - 29/09/2019
                              -- Monto m�ximo que se pueda otorgar para esa cobertura por canales
                                                        IF
                                                            nvl(vmon_max_cob_origen, 0) > 0
                                                            AND ( fonos_row.mon_pag > vmon_max_cob_origen )
                                                        THEN
                                                            error := '1';
                                                        END IF;
                              --
                                                        IF error IS NULL THEN
                                /***************************************************/
                                /*    Validar que el afiliado pueda reclamar en el plan del asegurado */
                                /***************************************************/
                                                            error1 := paq_matriz_validaciones.validar_plan_afiliado(fonos_row.plan, fonos_row.
                                                            tip_ser, fonos_row.tip_rec, fonos_row.afiliado);

                                -- DBMS_OUTPUT.PUT_LINE('Paq_Matriz_Validaciones.Validar_Plan_Afiliado 2 ');
                                                            IF error1 THEN
                                  /***************************************************/
                                  /*    Validar coberturas mutuamente excluyente     */
                                  /***************************************************/
                                                                error := paq_matriz_validaciones.valida_cob_excluyente(true, var_estatus_can,
                                                                var_tip_a_uso, cod_ase, cod_dep,
                                                                                                                      fonos_row.tip_ser,
                                                                                                                      fonos_row.tip_cob,
                                                                                                                      fonos_row.cobertura,
                                                                                                                      fecha_dia, var_fec_ini,
                                                                                                                      fonos_row.fec_ing,
                                                                                                                      pla_stc_row.frecuencia,
                                                                                                                      pla_stc_row.uni_tie_f,
                                                                                                                      fonos_row.plan);

                                                                IF error IS NULL THEN
                                    /***************************************************/
                                    /*    Validar Beneficio Maximo por Familia         */
                                    /***************************************************/
                                                                    error1 := paq_matriz_validaciones.validar_beneficio_max(fonos_row.
                                                                    compania, fonos_row.ramo, fonos_row.secuencial, fonos_row.plan, cod_ase,
                                                                                                                           fecha_dia,
                                                                                                                           var_fec_ini,
                                                                                                                           fonos_row.
                                                                                                                           fec_ing, fonos_row.
                                                                                                                           mon_pag, NULL);

                                                                    IF NOT ( error1 ) THEN
                                      /* --------------------------------------------- */
                                      /* Valida que el Monto Maximo digitado no exceda */
                                      /* el especificado en la Cobertura, solo para farmacias. */
                                      /* --------------------------------------------- */
                                                                        IF
                                                                            (
                                                                                fonos_row.mon_rec_afi IS NOT NULL
                                                                                AND fonos_row.mon_rec_afi <> 0
                                                                            )
                                                                            AND (
                                                                                pla_stc_row.mon_max IS NOT NULL
                                                                                AND pla_stc_row.mon_max <> 0
                                                                            )
                                                                        THEN
                                                                            IF ( nvl(dsp_mon_pag_acum, 0) + fonos_row.mon_pag ) < pla_stc_row.
                                                                            mon_max THEN
                                                                                var_code := 0;
                                                                            ELSE
                                                                                fonos_row.mon_rec_afi := pla_stc_row.mon_max - dsp_mon_pag_acum;
                                                                                var_code := 2;
                                                                            END IF;

                                                                        ELSE
                                                                            var_code := 0;
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
        IF var_code = 0 THEN
        -- Para verificar si no hay ningun error
        -- VALIDAR_COBERTURA: Funcion para controlar la cobertura 2836 ------------------------------
        -- * Esta cobertura solo estar� disponible en horario de 6:00 pm a 6:00 am
        -- * Las cl�nicas paquetes no deben reclamar por esta cobertura
        -- * Los m�dicos categor�a A+ (Platinum) est�n excepto de estas validaciones
        -- * Las excepciones deben poder ser manejadas por un superusuario
        -- * Para que el m�dico pueda reclamar el servicio el asegurado debe tener
        --   una reclamaci�n del mismo servicio (EMERGENCIA) por lo menos de 72 horas de antelaci�n.
        ---------------------------------------------------------------------------------------------

            IF fonos_row.tip_ser <> 3 THEN
          -- SERVICIO DE EMERGENCIA
          -- Suspencion por Suplantacion (Fraude)
                mfraude := 'N';

          -- para verificar si el afiliado tiene una marca de suspencion del servicio de salud
                OPEN c_fraude;
                FETCH c_fraude INTO mfraude;
                CLOSE c_fraude;
                IF mfraude = 'S' THEN
                    var_code := 2; -- VAR_CODE := 2;
                END IF;
          -- Fraude
            END IF;
        END IF; -- IF VAR_CODE <> 0 THEN

      --
      --<JDEVEAUX 18MAY2016>
      --Se restauran nuevamente los valores de la poliza voluntaria antes de salir de VALIDATECOBERTURA
        IF v_sec_ori IS NOT NULL THEN
            fonos_row.plan := v_plan_ori;
            fonos_row.compania := v_compania_ori;
            fonos_row.ramo := v_ramo_ori;
            fonos_row.secuencial := v_sec_ori;
        END IF;
      --</jdeveaux>

      -- Mirex
        IF fonos_row.plan = pkg_const.c_plan_mirex THEN
            IF v_deducible_mirex < 0 THEN
                v_deducible_mirex := 0;
            END IF;
            IF v_deducible_mirex >= fonos_row.mon_pag THEN
                fonos_row.mon_ded := fonos_row.mon_pag;
                fonos_row.mon_pag := 0;
            ELSE
                fonos_row.mon_pag := ( fonos_row.mon_pag - v_deducible_mirex );
                fonos_row.mon_ded := v_deducible_mirex;
            END IF;

        ELSE
        -- Si es otro plan distinto de mirex
            IF v_deducible_mirex < 0 THEN
                v_deducible_mirex := 0;
            END IF;
            IF v_deducible_mirex >= fonos_row.mon_pag THEN
                fonos_row.mon_ded := fonos_row.mon_pag;
                fonos_row.mon_pag := 0;
            ELSE
                fonos_row.mon_pag := ( fonos_row.mon_pag - v_deducible_mirex );
                fonos_row.mon_ded := v_deducible_mirex;
            END IF;

        END IF;
      ------ mirex

        fonos_row.mon_pag := round(fonos_row.mon_pag, 2);
        no_m_cob_row.limite := round(no_m_cob_row.limite, 2);
        fonos_row.por_coa := round(por_coa, 2);
        fonos_row.mon_ded := round(fonos_row.mon_ded, 2);
        IF fonos_row.tiene_excesoporgrupo = 'S'--- TIENE EXCESO POR GRUPO
         THEN
            UPDATE infox_session
            SET
                code = var_code,
                tip_ser = fonos_row.tip_ser,
                tip_cob = fonos_row.tip_cob,
                r_tip_cob = fonos_row.tip_cob,
                mon_rec = fonos_row.mon_pag, --NO_M_COB_ROW.LIMITE,
                mon_pag = v_monpag_devuelve_funcion,
                por_coa = fonos_row.por_coa,
                des_cob = cob_sal_row.descripcion,
                mon_rec_afi = fonos_row.mon_rec_afi,
                cobertura = fonos_row.cobertura,
                mon_ded = fonos_row.mon_ded,
                coberturastr = p_instr1
            WHERE
                CURRENT OF a;

            CLOSE a;
        --
            p_outstr1 := ltrim(to_char(fonos_row.mon_pag, '999999990.00'));
            p_outstr2 := ltrim(to_char(fonos_row.mon_ded, '999999990.00'));
            p_outnum1 := var_code;
            p_outnum2 := v_monpag_devuelve_funcion;
        --
        ELSE

        --
            UPDATE infox_session
            SET
                code = var_code,
                tip_ser = fonos_row.tip_ser,
                tip_cob = fonos_row.tip_cob,
                r_tip_cob = fonos_row.tip_cob,
                mon_rec = no_m_cob_row.limite,
                mon_pag = fonos_row.mon_pag,
                por_coa = fonos_row.por_coa,
                des_cob = cob_sal_row.descripcion,
                mon_rec_afi = fonos_row.mon_rec_afi,
                cobertura = fonos_row.cobertura,
                mon_ded = fonos_row.mon_ded,
                coberturastr = p_instr1
            WHERE
                CURRENT OF a;

            CLOSE a;
        --
            p_outstr1 := ltrim(to_char(fonos_row.mon_pag, '999999990.00'));
            p_outstr2 := ltrim(to_char(fonos_row.mon_ded, '999999990.00'));
            p_outnum1 := var_code;
        --
        END IF;

    END;
END;
