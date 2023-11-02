--------------------------------------------------------
--  DDL for Procedure P_VALIDATECOBERTURA_INT
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_VALIDATECOBERTURA_INT" (
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
    /* @% Verificar Disponibilidad de Cobertura */
    /* Descripcion : Valida que el Afiliado  pueda ofrecer la cobertura y que el asegurado*/
    /*               pueda recibir la cobertura. */
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
        var_frecuencia            NUMBER(3) := 1;
        var_uni_tie_f             pla_stc_row.uni_tie_f%TYPE;
        var_dsp_frec_acum         dsp_frec_acum%TYPE;
        vmon_max_cob_origen       NUMBER(11, 2);

      -- Varaibles provisionales--
        v_mon_ded_tip_cob         NUMBER(14, 2);
        v_mod_a_ded               VARCHAR2(1 BYTE);
        v_uni_tie_ded             NUMBER(3);
        v_ran_u_ded               VARCHAR2(3 BYTE);
        v_for_m_exc               VARCHAR2(1 BYTE);
        v_cal_cop_rang            VARCHAR2(10);
        v_no_apl_ser              VARCHAR2(10);
        var_plan                  NUMBER(4);
        var_tipo                  VARCHAR2(20);
        var_secuencial            NUMBER(8);
        v_error_handler           VARCHAR2(500);
        var_deducible             NUMBER;
        dsp_fec_ing               DATE;

      --<84770> DMENENES 29JUN2015
      --Variables para procesos de Salud Internacional
        v_mon_max                 NUMBER;
        v_dias_tip_cob            NUMBER;
        v_mon_disp_tc             NUMBER;
        v_var_ind_ded             VARCHAR2(10) := 'S'; -- agregado para mirex
        v_apl_ded_rie             VARCHAR2(10);
        v_ind_ded_rie             VARCHAR2(10);
        v_fec_i_car               DATE;
        v_fec_f_car               DATE;
        v_ind_ded_cas             VARCHAR2(10) := 'N';
        v_numero_caso             NUMBER;
        v_acum_rec_g              NUMBER;
        v_valida_limite           VARCHAR2(10);
        vafiliado_sal             NUMBER;
        dsp_uni_tie_f             NUMBER;
        var_uni_t_exe             NUMBER;
        dsp_tie_esp               NUMBER;
        dsp_uni_t_esp             NUMBER;
        var_mon_e_coa             NUMBER;
        var_for_e_coa             VARCHAR2(10);
        var_mon_r_ded             NUMBER;
        var_mon_coa               NUMBER;
      --</84770>

      --Enfoco mcarrion 12/02/2019
        v_prov_capitado           NUMBER(1) := 0;
        v_prov_basico             NUMBER;
        v_prov_existe             NUMBER;
        v_nuevo                   VARCHAR2(1);
      --Enfoco mcarrion 12/02/2019
        v_mon_rec_dg              NUMBER;
        v_reserva                 NUMBER;
        var_mod_a_ded             VARCHAR2(10);
        vmon_pag_tc               NUMBER;
        vmon_fee_tc               NUMBER;
        vmon_fee                  NUMBER;
        vflag_del_cob             VARCHAR2(10);
        v_msg                     VARCHAR2(100);
        v_red_plat                NUMBER(3);
      -- Technocons
        mfraude                   VARCHAR(1);
      --
        m_plan_exception          VARCHAR2(4000);
      --
        m_valida_plan             VARCHAR2(4000);
        v_grupo                   VARCHAR2(5);
        v_mirex                   NUMBER := to_number(dbaper.busca_parametro('PLAN_MIREX', fonos_row.compania));
      --
        v_monto_acumulado_cober   NUMBER; -- MONTO ACUMULADO DE TODAS LAS COBERTURAS DE UNA RECLAMACION.
      --
        p_ran_u_exc               lim_c_rec.ran_u_exc%TYPE;
        p_ran_u_max               lim_c_rec.ran_u_exc%TYPE;
      --
        vestudio_repeticion       VARCHAR2(1) := 'N';
        v_deducible_mirex         NUMBER;
        v_edad_afiliado           NUMBER;
        v_ano_servicio            NUMBER;
        v_monpag_devuelve_funcion NUMBER;
        vMESSAGE                  VARCHAR2(2000); --- MENSAJE DEL EXCESO POR GRUPO
     ------------------
        v_proveedor_int           NUMBER;
        v_categoria_int           NUMBER;
        CURSOR c_plan_exception IS
        SELECT
            valparam
        FROM
            tparagen d
        WHERE
            nomparam IN ( 'LIB_PLAN_FONO' )
            AND compania = fonos_row.compania;
      --
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
      --
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
            ase_carnet,
            sexo,
            fec_ing,
            fec_nac,
            ano_rec,
            sec_rec,
            categoria,
            est_civ,
            mon_rec_afi,
            cat_n_med,
            tip_ser
        FROM
            infox_session
        WHERE
            numsession = p_numsession;
      --
        CURSOR b IS
        SELECT
            tip_n_med.descripcion
        FROM
            no_medico,
            tipo_no_medico tip_n_med
        WHERE
                no_medico.codigo = fonos_row.afiliado
            AND tip_n_med.codigo = no_medico.tip_n_med;
      --
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
                      --AND TRUNC(POLIZA2.FEC_VER) <= FECHA_DIA);
                    AND poliza2.fec_ver < trunc(fecha_dia) + 1
            );

        CURSOR d IS
        SELECT
            descripcion
        FROM
            categoria_asegurado
        WHERE
            codigo = fonos_row.categoria;
      --
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
      --
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
      --
      --TP 09/11/2018 Enfoco
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
                    AND a.servicio = p.servicio
            );

        CURSOR cap_basico (
            p_proveedor NUMBER
        ) IS
        SELECT
            1
        FROM
            plan_afiliado
        WHERE
                plan = pkg_const.c_plan_basico
            AND afiliado = p_proveedor
            AND servicio = pkg_const.c_serv_odontologicos
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

        vdsp_fec_ing              DATE;
        edad_ase                  NUMBER;
      --
        CURSOR cur_ase IS
        SELECT
            fec_ing
        FROM
            asegurado
        WHERE
            codigo = vafiliado_sal;
      --
        CURSOR cur_dep IS
        SELECT
            fec_ing
        FROM
            dependiente
        WHERE
            codigo = vafiliado_sal;
      --
  ----Proceso Integracion de categoria a polizas Internacionales para planes Odontologicos tmm 7-7-2021    

-----------------------

        CURSOR cur_cat_prov IS
        SELECT
            a.afiliado,
            a.cat_pro
        FROM
            pol_pro a
        WHERE
                compania = fonos_row.compania
            AND ramo = fonos_row.ramo
            AND secuencial = fonos_row.secuencial
            AND plan = fonos_row.plan
            AND servicio = fonos_row.tip_ser
            AND estatus = pkg_const.e_pol_pro_vigente
            AND fec_ver = (
                SELECT
                    MAX(b.fec_ver)
                FROM
                    poliza_provedor b
                WHERE
                        a.compania = b.compania
                    AND a.ramo = b.ramo
                    AND a.secuencial = b.secuencial
                    AND a.plan = b.plan
                    AND a.tip_afi = b.tip_afi
                    AND a.afiliado = b.afiliado
                    AND a.servicio = b.servicio
            );



      /* Rutina Principal */
        vusuario                  VARCHAR2(15);
    BEGIN
      --
        vusuario := nvl(dbaper.f_busca_usu_registra_canales(user), 'FONOSALUD');
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
            fonos_row.ase_carnet,
            fonos_row.sexo,
            fonos_row.fec_ing,
            fonos_row.fec_nac,
            fonos_row.ano_rec,
            fonos_row.sec_rec,
            fonos_row.categoria,
            fonos_row.est_civ,
            fonos_row.mon_rec_afi,
            fonos_row.cat_n_med,
            fonos_row.tip_ser;

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
                v_inser := 8; --TP 09/11/2018 Enfoco
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
        --
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
        --
            fonos_row.tip_cob := v_intip;
            fonos_row.cobertura := v_incob;
            var_tip_ser2 := fonos_row.tip_ser;
        --

        --Enfoco mcarrion 12/02/2019
            IF
                fonos_row.tip_rec = 'NO_MEDICO'
                AND fonos_row.tip_ser = 8       ---se agrego la validciona para los medicos en internacinal porque 
            OR fonos_row.tip_rec = 'MEDICO'
            AND fonos_row.tip_ser = 8 THEN     ---porque si llevan un proveedor de odontologia

                OPEN cur_prov_capitado;
                FETCH cur_prov_capitado INTO
                    v_prov_capitado,
                    v_prov_basico;
                CLOSE cur_prov_capitado;
          --
                OPEN cap_basico(fonos_row.afiliado);
                FETCH cap_basico INTO v_prov_existe;
                CLOSE cap_basico;
          --
                OPEN nuevo(v_prov_basico);
                FETCH nuevo INTO v_nuevo;
                CLOSE nuevo;
          --
                IF
                    v_prov_capitado = 1
                    AND nvl(v_prov_existe, 0) = 0
                    AND nvl(v_nuevo, 'N') = 'N'
                THEN
            --
                    var_code := 2; --MSG_ALERT('Afiliado tiene un plan capitado, o debe pasar reclamaciones.','E', TRUE);
            --

                ELSE
            ----Proceso Integracion de categoria a polizas Internacionales para planes Odontologicos tmm 7-7-2021  
                    IF ( (
                        fonos_row.tip_rec = 'NO_MEDICO'
                        AND fonos_row.tip_ser = 8
                    ) OR (
                        fonos_row.tip_rec = 'MEDICO'
                        AND fonos_row.tip_ser = 8
                    ) ) THEN
                        OPEN cur_cat_prov;
                        FETCH cur_cat_prov INTO
                            v_proveedor_int,
                            v_categoria_int;
                        CLOSE cur_cat_prov;
                    END IF;
                END IF;

            END IF;
        ---Enfoco mcarrion 12/02/2019
        --
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
          --
                IF error IS NULL THEN
                    error := f_buscar_datos_cobertura(fonos_row, var_tip_ser2, fonos_row.tip_cob, ser_sal_row.descripcion, tip_c_sal_row.
                    descripcion,
                                                     cob_sal_row.descripcion, no_m_cob_row.limite, no_m_cob_row.por_des);
            /*SYSDATE,
            FONOS_ROW.CAT_N_MED,
            DAT_ASEG_ROW
            );*/
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
              --
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
              --
                        IF error IS NULL THEN
                /* ----------------------------------------------------------------------*/
                /* --------------------------------------------------------------------- */
                /*  Busca Limite de monto por cobertura de salud                         */
                /* --------------------------------------------------------------------- */

                /* If..End if adicionado para condicionar si la poliza esta exento
                   de restriccion.  Roche Louis/TECHNOCONS. d/f 17-Dic-2009 8:57am
                */
                            IF NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, fonos_row.ramo, fonos_row.
                            secuencial, fonos_row.plan, fonos_row.tip_ser,
                                                                                      fonos_row.tip_cob, fonos_row.cobertura) THEN

                  --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                                limite_laboratorio := dbaper.paq_reclamacion_si.f_tip_cob_mon_max(fonos_row.compania, fonos_row.ramo,
                                fonos_row.secuencial, fonos_row.plan, fonos_row.tip_ser,
                                                                                                 fonos_row.tip_cob, p_mon_exe, p_uni_t_exe,
                                                                                                 p_ran_exe, p_por_coa,
                                                                                                 p_uni_t_max, v_mon_ded_tip_cob, -- Variable Provisional
                                                                                                  v_mod_a_ded, -- Variable Provisional
                                                                                                  v_uni_tie_ded, -- Variable Provisional
                                                                                                  v_ran_u_ded, -- Variable Provisional
                                                                                                 v_for_m_exc, -- Variable Provisional
                                                                                                  fecha_dia, -- Variable Provisional
                                                                                                  var_frecuencia, -- Variable Provisional
                                                                                                  fonos_row.tip_rec, -- Variable Provisional
                                                                                                  fonos_row.afiliado, -- Variable Provisional
                                                                                                 v_cal_cop_rang, -- Variable Provisional
                                                                                                  v_no_apl_ser, -- Variable Provisional)
                                                                                                  trunc(sysdate), v_error_handler);
                  --
                            END IF;
                --<84770>
                --
                --P_MON_DED_TIP_COB);
                /* --------------------------------------------------------------------- */
                /* Valida que el Asegurado puede Recibir la Cobertura de Salud.          */
                /* --------------------------------------------------------------------- */
                            IF
                                fonos_row.tip_ser = 8
                                AND v_proveedor_int IN ( 4014, 4013, 4012, 5372, 1942 )
                            THEN
                                error := paq_matriz_validaciones.chk_cobertura_asegurado_fono(true, fonos_row.tip_rec, fonos_row.afiliado,
                                des_tip_n_med, var_tip_a_uso,
                                                                                             cod_ase, cod_dep, fonos_row.compania, fonos_row.
                                                                                             ramo, fonos_row.secuencial,
                                                                                             fonos_row.plan, fonos_row.tip_ser, fonos_row.
                                                                                             tip_cob, fonos_row.cobertura, var_tip_ser2,
                                                                                             fecha_dia, fonos_row.sexo, fonos_row.est_civ,
                                                                                             var_categoria, fonos_row.fec_nac,
                                                                                             por_coa, no_m_cob_row.limite, pla_stc_row.
                                                                                             frecuencia, pla_stc_row.uni_tie_f, pla_stc_row.
                                                                                             tie_esp,
                                                                                             pla_stc_row.uni_tie_t, pla_stc_row.mon_max, --A--
                                                                                              pla_stc_row.uni_tie_m, pla_stc_row.sexo,
                                                                                             pla_stc_row.eda_min,
                                                                                             pla_stc_row.eda_max, p_dsp_est_civ, p_dsp_categoria,
                                                                                             monto_contratado, vusuario,
                                                                                             p_por_coa, p_monto_max, --A estaba dos veces--
                                                                                              pla_stc_row.exc_mca, pla_stc_row.mon_ded,
                                                                                             v_categoria_int,
                                                                                             v_proveedor_int);

                            ELSE
                                error := paq_matriz_validaciones.chk_cobertura_asegurado_fono(true, fonos_row.tip_rec, fonos_row.afiliado,
                                des_tip_n_med, var_tip_a_uso,
                                                                                             cod_ase, cod_dep, fonos_row.compania, fonos_row.
                                                                                             ramo, fonos_row.secuencial,
                                                                                             fonos_row.plan, fonos_row.tip_ser, fonos_row.
                                                                                             tip_cob, fonos_row.cobertura, var_tip_ser2,
                                                                                             fecha_dia, fonos_row.sexo, fonos_row.est_civ,
                                                                                             var_categoria, fonos_row.fec_nac,
                                                                                             por_coa, no_m_cob_row.limite, pla_stc_row.
                                                                                             frecuencia, pla_stc_row.uni_tie_f, pla_stc_row.
                                                                                             tie_esp,
                                                                                             pla_stc_row.uni_tie_t, pla_stc_row.mon_max, --A--
                                                                                              pla_stc_row.uni_tie_m, pla_stc_row.sexo,
                                                                                             pla_stc_row.eda_min,
                                                                                             pla_stc_row.eda_max, p_dsp_est_civ, p_dsp_categoria,
                                                                                             monto_contratado, vusuario,
                                                                                             p_por_coa, p_monto_max, --A estaba dos veces--
                                                                                              pla_stc_row.exc_mca, pla_stc_row.mon_ded);
                            END IF;

                            dbms_output.put_line('CHK_COBERTURA_ASEGURADO_FONO INTERNACIONAL:'
                                                 || error
                                                 || ' Categoria:'
                                                 || v_categoria_int
                                                 || ' proveedor:'
                                                 || v_proveedor_int);

                            IF error IS NULL THEN
                  /*---------------------------------------------------------- */
                  /* Valida que no se este digitando una Reclamacion           */
                  /* que ya fue reclamada por el mismo.                        */
                  /* --------------------------------------------------------- */
                                sec_reclamacion := paq_matriz_validaciones.valida_rec_fecha_null(true, var_estatus_can, fonos_row.ano_rec,
                                fonos_row.compania, fonos_row.ramo,
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
                            --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                                                    error := dbaper.paq_reclamacion_si.f_validar_frec_cobertura(true, var_estatus_can,
                                                    var_tip_a_uso, cod_ase, cod_dep,
                                                                                                               fonos_row.tip_ser, fonos_row.
                                                                                                               tip_cob, fonos_row.compania,
                                                                                                               fonos_row.ramo, fonos_row.
                                                                                                               secuencial,
                                                                                                               fonos_row.cobertura, fecha_dia,
                                                                                                               var_fec_ini, fonos_row.
                                                                                                               fec_ing, pla_stc_row.frecuencia,
                                                                                                               pla_stc_row.uni_tie_f,
                                                                                                               pla_stc_row.tie_esp, pla_stc_row.
                                                                                                               uni_tie_t, pla_stc_row.
                                                                                                               mon_max, pla_stc_row.uni_tie_m,
                                                                                                               dsp_frec_acum, dsp_mon_pag_acum,
                                                                                                               var_plan, trunc(sysdate),
                                                                                                               v_error_handler);
                            --
                                                END IF;
                          --</84770>
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
                              /* si tiene monto excento por tipo de cobertura                   */
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

                                --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                                                            p_mon_acum := dbaper.paq_reclamacion_si.f_busca_rec_acu(var_tip_a_uso, cod_ase,
                                                            cod_dep, fecha_dia, fonos_row.compania,
                                                                                                                   fonos_row.ramo, fonos_row.
                                                                                                                   plan, fonos_row.tip_ser,
                                                                                                                   fonos_row.tip_cob,
                                                                                                                   var_estatus_can,
                                                                                                                   t_fec_ini, t_fec_fin,
                                                                                                                   var_tipo, -- Variable Provisional
                                                                                                                    var_secuencial, -- Variable Provisional
                                                                                                                    trunc(sysdate));

                                                            dbms_output.put_line('PAQ_RECLAMACION_SI.F_BUSCA_REC_ACU:'
                                                                                 || error
                                                                                 || ' monto acumulado:'
                                                                                 || p_mon_acum);                                                          
                                --</84770>
                                                        END IF;
                              --Se iguala variable al Monto a Pagar para enviar al proceso que obtiene deducible Salud Internacional
                              --<84770>

                                                        var_deducible := nvl(var_deducible, 0); --<84770.4> JTAVERAS

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
                                                        vafiliado_sal := NULL;/*dbaper.paq_sync_reclamacion.f_busca_asegurado(COD_ASE,
                                                                                             nvl(cod_dep,
                                                                                                 0), --<84770.4> JTAVERAS
                                                                                             fonos_row.compania,
                                                                                             fonos_row.ramo,
                                                                                             fonos_row.secuencial,
                                                                                             VAR_TIP_A_USO);*/
                              --</84770>
                              -- Migracion Salud internacional
                                                        IF ( vafiliado_sal IS NULL OR vafiliado_sal = 0 ) THEN
                                                            vafiliado_sal := dbaper.paq_reclamacion_si.f_ase_dep_codigo(cod_ase, cod_dep,
                                                            fonos_row.compania, fonos_row.ramo, fonos_row.secuencial);
                                                        END IF;
                              --<84770> DMENENES 29JUN2015
                              --Proceso que busca el deducible del plan elegido por el asegurado en SaludCore

                                                        v_error_handler := dbaper.paq_reclamacion_si.f_obt_datos_ded(1, v_mon_max, v_dias_tip_cob,

                                                        v_mon_disp_tc, no_m_cob_row.limite, --               ,
                                                                                                                    var_frecuencia, fonos_row.
                                                                                                                    tip_cob, fonos_row.
                                                                                                                    secuencial, fonos_row.
                                                                                                                    ramo, fonos_row.compania,
                                                                                                                    fonos_row.ano_rec,
                                                                                                                    'A', 'A', v_var_ind_ded,
                                                                                                                    fonos_row.secuencial,
                                                                                                                    fonos_row.plan, vafiliado_sal,
                                                                                                                    var_tip_a_uso, fecha_dia,
                                                                                                                    'L',
                                                                                                                    'P', v_apl_ded_rie,
                                                                                                                    v_ind_ded_rie, var_fec_ini, --t_fec_ini                            ,
                                                                                                                     dsp_fec_ing,
                                                                                                                    fonos_row.tip_ser,
                                                                                                                    fonos_row.cobertura,
                                                                                                                    'S', v_fec_i_car,
                                                                                                                    v_fec_f_car,
                                                                                                                    v_ind_ded_cas, v_numero_caso,
                                                                                                                    var_deducible, --<84770.4> JTAVERAS :REC_C_SAL13.VAR_DEDUCIBLE ,
                                                                                                                     fonos_row.mon_rec, --<84770.4> JTAVERAS V_MON_PAG_DG              ,
                                                                                                                     v_acum_rec_g,
                                                                                                                    fonos_row.mon_rec, --<84770.4> JTAVERAS V_MON_PAG_DG                           ,
                                                                                                                     fonos_row.mon_rec, --<84770.4> JTAVERAS V_MON_PAG_BK                         ,
                                                                                                                     v_reserva, v_valida_limite,
                                                                                                                    0); --<84770.4> JTAVERAS :rec_c_sal13.sum_mon_pag

                              --<84770.4> JTAVERAS
                                                        dbms_output.put_line('paq_reclamacion_si.F_OBT_DATOS_DED:' || v_error_handler);
                                                        v_deducible_mirex := 0;
                                                        v_deducible_mirex := var_deducible;
                              --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                                                        v_error_handler := paq_reclamacion_si.f_buscar_coaseg_frec_monto(fonos_row.tip_rec,
                                                        fonos_row.afiliado, var_tip_a_uso, cod_ase, cod_dep,
                                                                                                                        fonos_row.compania,
                                                                                                                        fonos_row.ramo,
                                                                                                                        fonos_row.secuencial,
                                                                                                                        fonos_row.plan,
                                                                                                                        fonos_row.tip_ser,
                                                                                                                        fonos_row.tip_cob,
                                                                                                                        fonos_row.cobertura,
                                                                                                                        fecha_dia, por_coa,
                                                                                                                        no_m_cob_row.
                                                                                                                        limite,
                                                                                                                        var_frecuencia,
                                                                                                                        dsp_uni_tie_f,
                                                                                                                        var_uni_t_exe,
                                                                                                                        v_mon_max, dsp_tie_esp,
                                                                                                                        dsp_uni_t_esp,
                                                                                                                        'GEN', fecha_dia);

                                                        dbms_output.put_line('paq_reclamacion_si.F_BUSCAR_COASEG_FREC_MONTO:' || v_error_handler);                                                                    
                              --</84770>

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

                                                        var_frecuencia := 1;

                              --<84770> jdeveaux --> Se reemplaza por procesos que busca en SaludCore
                                                        dbaper.paq_reclamacion_si.p_calcular_reserva(no_m_cob_row.limite * var_frecuencia,
                                                        no_m_cob_row.limite, var_frecuencia, por_coa, no_m_cob_row.por_des,
                                                                                                    v_reserva, fonos_row.mon_pag, v_mon_max,
                                                                                                    p_mon_acum,
                                                                           -- :OBJETAR_RADICACION.VAR_MON_EXE *Este par�metro no se encuentra en el procedimiento del paquete.
                                                                                                     var_mon_e_coa, -- Variable Provisional
                                                                                                    var_for_e_coa, -- Variable Provisional
                                                                                                     var_deducible, -- Variable Provisional
                                                                                                     var_mod_a_ded, -- Variable Provisional
                                                                                                     var_mon_r_ded, -- Variable Provisional
                                                                                                     var_mon_coa, -- Variable Provisional
                                                                                                    fecha_dia, v_error_handler);

                              ----- AGREGADO PARA BUSCAR EL GRUPO Y ENVIARLO A LA FUNCION.
                                                        v_grupo := 'GEN';
                                                        IF to_number(v_mirex) = to_number(fonos_row.plan) THEN
                                                            v_grupo := dbaper.val_grupo_x_tip_cob_grupo(fonos_row.plan, fonos_row.tip_ser,
                                                            fonos_row.tip_cob);
                                                        END IF;
                              -----
                                                        IF var_tip_a_uso = 'ASEGURADO' THEN
                                                            OPEN cur_ase;
                                                            FETCH cur_ase INTO vdsp_fec_ing;
                                                            CLOSE cur_ase;
                                                        ELSE
                                                            OPEN cur_dep;
                                                            FETCH cur_dep INTO vdsp_fec_ing;
                                                            CLOSE cur_dep;
                                                        END IF;
                              --
                                                        v_edad_afiliado := NULL;
                                                        v_edad_afiliado := trunc(((months_between(trunc(sysdate), fonos_row.fec_nac)) /
                                                        12), 0);

                                                        v_ano_servicio := to_char(sysdate, 'yyyy');
                                                        vMESSAGE := NULL;

                              ----------- ESTE BLOQUE ES PARA CONTROLAR EL TEMA DE CUANDO SE LLEGA AL LIMITE EN MEDIO DE UNA RECLAMACION.

                                                        dbaper.paq_reclamacion_si.p_val_mon_max_gru(v_ano_servicio, --fonos_row.ano_rec,

                                                         fonos_row.compania, fonos_row.ramo, fonos_row.secuencial, fonos_row.plan,
                                                                                                   vafiliado_sal, --:RECLAMAC12.ASE_USO
                                                                                                    var_tip_a_uso, v_edad_afiliado, --<8477.4> JTAVERAS 09JUL2015 null
                                                                                                    fecha_dia, var_fec_ini,
                                                                                                   vdsp_fec_ing, NULL, --fonos_row.secuencial
                                                                                                    fonos_row.tip_cob, fonos_row.mon_pag, --V_MON_REC_DG
                                                                                                    fonos_row.mon_pag, --VMON_PAG_TC
                                                                                                   v_grupo, nvl(vmon_fee_tc, 0), vmon_fee,
                                                                                                   vMESSAGE, fonos_row.mon_pag, 'N', --VFLAG_DEL_COB
                                                                                                   fecha_dia);

                                                        v_monpag_devuelve_funcion := fonos_row.mon_pag;
                                                        fonos_row.TIENE_EXCESOPORGRUPO := CASE WHEN vMESSAGE IS NULL THEN 'N' ELSE 'S' END;
                                                        
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
                                /* ----------------------------------------------------------------------- */
                                /* Obtiene la Fecha Inicial segun la Unidad de Tiempo                      */
                                /* de monto maximo para determinar si ha excedido el Uso de la Cobertura.  */
                                /* ----------------------------------------------------------------------- */
                                                            t_fec_ini := paq_matriz_validaciones.determina_fecha_rango(fecha_dia, var_fec_ini,
                                                            NULL, NULL, NULL,
                                                                                                                      p_ran_u_exc, limite_laboratorio,
                                                                                                                      nvl(p_uni_t_max,
                                                                                                                      365));
                                /* ---------------------------------------------------------------------- */
                                /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto maximo       */
                                /* para determinar si ha excedido el Uso maximo de la Cobertura.          */
                                /* ---------------------------------------------------------------------- */
                                                            t_fec_fin := paq_matriz_validaciones.determina_fecha_rango_fin(fecha_dia,
                                                            var_fec_ini, NULL, NULL, NULL,
                                                                                                                          limite_laboratorio,
                                                                                                                          nvl(p_uni_t_max,
                                                                                                                          365), p_ran_u_exc);
                                /* Si la Fecha Fin es null, entonces sera igual */
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
      --<84770> jdeveaux --> Se busca si tiene poliza local
      --      dbaper.paq_reclamacion_si.p_busca_polizas (fonos_row.compania, cod_ase, cod_dep, fecha_dia, v_ramo, v_sec_pol, 'LOCAL');
      --</84770>

        IF (
            var_code = 0
            AND nvl(fonos_row.mon_pag, 0) > 0
        ) /* or (v_sec_pol is null)*/ THEN
        --<84770> jdeveaux --> Se condiciona a que solo grabe si tiene cobertura o si no tiene poliza local

            fonos_row.mon_pag := round(fonos_row.mon_pag, 2);
            no_m_cob_row.limite := round(no_m_cob_row.limite, 2);
            fonos_row.por_coa := round(por_coa, 2);
            fonos_row.mon_ded := round(fonos_row.mon_ded, 2);
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
                mon_ded = var_deducible,
                coberturastr = p_instr1,
                TIENE_EXCESOPORGRUPO = NVL(fonos_row.TIENE_EXCESOPORGRUPO,'N')
            WHERE
                numsession = p_numsession;

            CLOSE a;

        -- Victor Acevedo / TECHNOCONS.
            p_outstr1 := ltrim(to_char(fonos_row.mon_pag, '999999990.00'));
            p_outstr2 := ltrim(to_char(nvl(fonos_row.mon_ded, 0), '999999990.00'));

            p_outnum1 := var_code;
        ELSE
        --<84770> jdeveaux --> Si tiene poliza local y no tiene cobertura internacional, se procesa por el plan local
           
            p_validateasegurado_loc(p_numsession, fonos_row.ase_carnet, p_outnum1, p_outnum2);
            IF p_outnum1 = 0 THEN --local
                p_validatecobertura_loc(p_numsession, p_instr1, p_instr2, v_deducible_mirex, v_monpag_devuelve_funcion,
                                       p_outstr1, p_outstr2, p_outnum1, p_outnum2);
            END IF;

        END IF;
      --  end if; --MIREX
    END;
