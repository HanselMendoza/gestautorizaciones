CREATE OR REPLACE PROCEDURE p_validatecobertura (
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
    v_pss_no_cambia_covid     NUMBER;
    dummy                     VARCHAR2(1);
    error                     CHAR(1);
    v_puede_dar_servicio      BOOLEAN; /*  Se utiliza igual que ERROR, pero es enviada en algunos casos que la funcion devuelve boolean */
    v_excede_monto_maximo     BOOLEAN;
    red_excepcion_odon        BOOLEAN;
    cat_plan_odon             BOOLEAN;
    var_code                  NUMBER(2) := 1;
      --
    var_cod_err               NUMBER := NULL;  --Varible para manejar el codigo de error que se interpretara en la emergencia por el monto Miguel A. Carrion FCCM 15/10/2021
      --
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
    v_param                   tparagen.valparam%TYPE := f_obten_parametro_seus('PLA_SAL_INT');
    v_internacional           VARCHAR2(1);
    v_msg                     VARCHAR2(100);
    v_red_plat                NUMBER(3);
    p_ran_u_exc               lim_c_rec.ran_u_exc%TYPE;
    p_ran_u_max               lim_c_rec.ran_u_exc%TYPE;
      -- Technocons
    mfraude                   VARCHAR(1);
    vmon_max_cob_origen       NUMBER(11, 2);
    m_plan_exception          VARCHAR2(4000);
    m_valida_plan             VARCHAR2(4000); --

      --<jdeveaux 18may2016>
      --Variables para capturar los datos de la poliza original de plan voluntario cambia a la poliza del plan basico
    v_plan_ori                NUMBER(3);
    v_compania_ori            NUMBER(2);
    v_ramo_ori                NUMBER(2);
    v_sec_ori                 NUMBER(7);
      --</jdeveaux>
    vestudio_repeticion       VARCHAR2(1) := 'N';
      --Enfoco mcarrion 12/02/2019
    v_prov_capitado           NUMBER(1) := 0;
    v_prov_basico             NUMBER;
    v_prov_existe             NUMBER;
    v_nuevo                   VARCHAR2(1);
      --Enfoco mcarrion 12/02/2019
      --
    v_secuencial_precert      NUMBER;
      --
    v_serv_eme                NUMBER;
    
    --fclark 21-Jun-22
    -- variables que estaban declaradas globalmente a nivel de pkg_infox_htpa
    -- movidas a este proc, que es donde realmente se usan
    f_fec_ver                 DATE;
    v_fec_final               DATE;
    v_fec_final_gmm           DATE := NULL;
    v_bce_ac                  NUMBER(14, 2) := 0;
    v_lim_ac                  NUMBER(14, 2) := 0;
    v_total_consumo           NUMBER(14, 2) := 0;
    valor_max_ac              NUMBER(14, 2) := 0;
    valor_max_gmm             NUMBER(14, 2) := 0;
    balance_gmm               NUMBER := 0;
    v_simultaneo              VARCHAR2(1);
    v_monto_cober             NUMBER(11, 2);
    v_error                   NUMBER;
    v_desc_error              VARCHAR2(100);
    v_notas                   VARCHAR2(100);
    var_tip_rec               VARCHAR2(10);
    v_nss                     NUMBER;
    v_monpag_devuelve_funcion NUMBER := 0;
    v_existe                  BOOLEAN := false;
    v_afiliado_vigente_pbs    BOOLEAN;
    v_plan_pbs                NUMBER(3);
    v_compania_pbs            NUMBER(2);
    v_ramo_pbs                NUMBER(2);
    v_sec_pbs                 NUMBER(7);
    v_servicio_renal          NUMBER(5);
    v_servicio_altocosto      NUMBER(5);
  --------
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

    CURSOR c_infox_sesion IS
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
        tip_ser
    FROM
        infox_session
    WHERE
        numsession = p_numsession;

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
                      --AND TRUNC(POLIZA2.FEC_VER) <= FECHA_DIA); --*--
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

    CURSOR c_numpla (
        p_cod_ase NUMBER,
        p_cod_dep NUMBER
    ) IS
    SELECT
        num_pla
    FROM
        afiliado_plasticos afi_pla
    WHERE
            afi_pla.asegurado = p_cod_ase
        AND afi_pla.secuencia = p_cod_dep
        AND afi_pla.fec_ver = (
            SELECT
                MAX(z.fec_ver)
            FROM
                afiliado_plasticos z
            WHERE
                    z.asegurado = afi_pla.asegurado
                AND z.secuencia = afi_pla.secuencia
                AND z.fec_ver < trunc(sysdate) + 1
        )
        AND afi_pla.fec_u_act = (
            SELECT
                MAX(z.fec_u_act) d
            FROM
                afiliado_plasticos z
            WHERE
                    z.asegurado = afi_pla.asegurado
                AND z.secuencia = afi_pla.secuencia
                AND z.fec_ver = afi_pla.fec_ver
        );

    v_num_pla                 NUMBER;
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

    CURSOR c_proveedor (
        p_compania NUMBER,
        p_ramo     NUMBER,
        p_sec_pol  NUMBER,
        p_plan     NUMBER,
        p_servicio NUMBER
    ) IS
    SELECT
        '1'
    FROM
        poliza_provedor p
    WHERE
            compania = p_compania
        AND ramo = p_ramo
        AND secuencial = p_sec_pol
        AND plan = p_plan
        AND servicio = p_servicio;

    v_proveedor               NUMBER;
    v_categoria               NUMBER;
    CURSOR c_pss_no_cambia_covid (
        p_codigo_pss NUMBER
    ) IS
    SELECT
        1
    FROM
        dbaper.pss_no_cambia_covid
    WHERE
        codigo_pss = p_codigo_pss;

    CURSOR c_busca_nss_ase IS
    SELECT
        nss
    FROM
        dbaper.asegurado a
    WHERE
        a.codigo = cod_ase;

    CURSOR c_busca_nss_dep IS
    SELECT
        nss
    FROM
        dbaper.dependiente
    WHERE
            asegurado = cod_ase
        AND secuencia = nvl(cod_dep, 0);

    vusuario                  VARCHAR2(15);
    /* Rutina Principal */
BEGIN

    OPEN c_infox_sesion;
    FETCH c_infox_sesion INTO
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
        fonos_row.tip_ser;

        v_existe := c_infox_sesion%FOUND;
    CLOSE c_infox_sesion;

    IF NOT v_existe THEN
        p_outnum1 := 1;
        return;
    END IF;

    v_inser := to_number(substr(p_instr1, 1, 2));
    v_intip := to_number(substr(p_instr1, 3, 2));
    v_incob := substr(p_instr1, 5, 10);
    
    vusuario := nvl(dbaper.f_busca_usu_registra_canales(user), 'FONOSALUD');
    fecha_dia := to_date(to_char(sysdate, 'dd/mm/yyyy'), 'dd/mm/yyyy');
    --
    v_afiliado_vigente_pbs := dbaper.f_afiliado_vigente_basico(fonos_row.asegurado, nvl(fonos_row.dependiente, 0), trunc(sysdate));
    dbaper.paq_pbs.poliza_pbs(v_compania_pbs, v_ramo_pbs, v_sec_pbs, v_plan_pbs);

    --
    IF fonos_row.ramo <> v_ramo_pbs 
        AND v_intip = pkg_const.c_tipcob_cons_emergencia AND v_afiliado_vigente_pbs 
    THEN
        fonos_row.compania := v_compania_pbs;
        fonos_row.ramo := v_ramo_pbs;
        fonos_row.secuencial := v_sec_pbs;
        fonos_row.plan := v_plan_pbs;
                            ---
        UPDATE infox_session
        SET
            compania = fonos_row.compania,
            ramo = fonos_row.ramo,
            secuencial = fonos_row.secuencial,
            plan = fonos_row.plan
        WHERE
            numsession = p_numsession;
    END IF;
    --END IF;
       ---- FIN VALIDACION DE CAMBIO DE COMPANIA Y PLAN PARA AFILIADOS CON BASICO VIGENTE EN PRUEBA DE COVID -- 12 04 2021       

    --<84770> jdeveaux --> Si es un plan internacional se debe ir por el proceso internacional
    IF fonos_row.ramo = pkg_const.c_ramo_salud_int
        OR instr(v_param, ','
                            || fonos_row.plan
                            || ',') > 0
    THEN
        v_internacional := 'S';
        p_validatecobertura_int(p_numsession, p_instr1, p_instr2, p_innum1, p_innum2,
                               p_outstr1, p_outstr2, p_outnum1, v_monpag_devuelve_funcion);

        fonos_row.mon_ded := nvl(to_number(p_outstr1), 0);

        SELECT
            tiene_excesoporgrupo 
            INTO fonos_row.tiene_excesoporgrupo
        FROM
            infox_session
        WHERE
            numsession = p_numsession;
      --
        IF nvl(fonos_row.tiene_excesoporgrupo, 'N') = 'S' THEN
            p_outstr1 := ltrim(to_char(v_monpag_devuelve_funcion, '999999990.00'));
            p_outstr2 := ltrim(to_char(fonos_row.mon_ded, '999999990.00'));
            p_outnum2 := 5;
        END IF;
        RETURN;
    END IF; 
    --</84770> jdeveaux --> Si es un plan internacional se procesa por el proceso internacional

    v_serv_eme := dbaper.busca_parametro('TIP_SERV_CONS_MEDI_3', fonos_row.compania);
    v_servicio_altocosto := dbaper.busca_parametro('TIP_SERV_CONS_MEDI_0',fonos_row.compania);
    v_servicio_renal :=  TO_NUMBER(PKG_GENERAL.F_OBTEN_PARAMETRO_SEUS('SERVICIO_RENAL', fonos_row.compania));
  
    OPEN d;
    FETCH d INTO var_categoria;
    CLOSE d;
    --
    cod_ase := to_number(fonos_row.asegurado);
    cod_dep := to_number(fonos_row.dependiente);

    IF nvl(cod_ase, 0) = 0 THEN
        p_outnum1 := 1;
        return;
    END IF;
    --
    IF nvl(cod_dep, 0) = 0 THEN
        var_tip_a_uso := 'ASEGURADO';
        OPEN c_busca_nss_ase;
        FETCH c_busca_nss_ase INTO v_nss;
        CLOSE c_busca_nss_ase;
    --
    ELSE
        var_tip_a_uso := 'DEPENDIENT';
        OPEN c_busca_nss_dep;
        FETCH c_busca_nss_dep INTO v_nss;
        CLOSE c_busca_nss_dep;
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
    IF v_intip = pkg_const.c_tipcob_cons_emergencia THEN
        v_inser := pkg_const.c_ser_promocion_prev; --wrs 1.0,22/09/2021
    ELSIF
        v_intip > pkg_const.c_tipcob_cons_emergencia
        AND v_intip <> pkg_const.c_tipcob_med_ambulatoria
    THEN
        v_inser := pkg_const.c_ser_emergencia;
    ELSE
        v_inser := pkg_const.c_ser_ambulatorio;
    END IF;

    OPEN c_numpla(cod_ase, cod_dep);
    FETCH c_numpla INTO v_num_pla;
    CLOSE c_numpla;

    -- Procedimiento que valida si la cobertura es un estudio a Repeticion  Miguel A.Carrion 06/09/2021
    vestudio_repeticion := f_busca_cob_estudio_repeticion(fonos_row.asegurado, 
            fonos_row.dependiente, fonos_row.compania, fonos_row.
            ramo, fonos_row.secuencial, fonos_row.tip_ser, nvl(fonos_row.tip_cob, v_intip), 
            nvl(fonos_row.cobertura, v_incob), vusuario);

    dbms_output.put_line('vESTUDIO_REPETICION->:  ' || vestudio_repeticion);
    IF nvl(vestudio_repeticion, 'N') = 'S' THEN
        DECLARE
            p_cantidad NUMBER;
            p_fec_ver  DATE;
            p_fec_fin  DATE;
            p_servicio NUMBER;
            p_tip_cob  NUMBER;
            p_error    NUMBER;
        BEGIN

                /*Procedimiento que busca en que bajo que servicio fue que se realizo la autorizacion de la cobertura de estudio
                    a repeticion y la parametrizacion de la cantidad y rango de fecha la cual iniciara y concluira el ciclo de la
                    autorizacion Miguel A. Carrion  06/09/2021*/
            dbaper.p_estudio_repeticion(fonos_row.asegurado, fonos_row.dependiente, nvl(fonos_row.cobertura, v_incob), fonos_row.
                    compania, p_cantidad, p_fec_ver, p_fec_fin,
                    p_servicio, p_tip_cob, p_error);
            IF p_error != 0 THEN
                p_outnum1 := 2;
                return;
            END IF;
                --
            v_inser := p_servicio;
            v_intip := p_tip_cob;
                --

            /*Funcion que valida si el afiliado concluyo con el ciclo de autorizacion segun lo parametrizado
            para la cobertura a repeticion Miguel A. Carrion 6/09/2021*/

            error := dbaper.f_validar_ciclo_cobertura_rep(var_estatus_can, var_tip_a_uso, 
                fonos_row.asegurado, fonos_row.dependiente, p_servicio,
                p_tip_cob, nvl(fonos_row.cobertura, v_incob), fecha_dia, p_fec_ver,
                p_fec_fin, p_cantidad,fonos_row.compania);

            IF error IS NOT NULL OR fecha_dia NOT BETWEEN p_fec_ver AND p_fec_fin THEN
                p_outnum1 := 2;
                return;
            END IF;
        END;
    END IF;

    --TP 09/11/2018 Enfoco
    IF fonos_row.tip_rec = 'MEDICO' THEN
        OPEN cat_medico(fonos_row.afiliado);
        FETCH cat_medico INTO v_cat;
        IF cat_medico%found THEN
            v_inser := pkg_const.c_serv_odontologicos;
        END IF;
        CLOSE cat_medico;
    ELSE
        OPEN cat_n_med(fonos_row.afiliado);
        FETCH cat_n_med INTO v_cat;
        IF cat_n_med%found THEN
            v_inser := pkg_const.c_serv_odontologicos;
        END IF;
        CLOSE cat_n_med;
    END IF;
    --TP 09/11/2018 Enfoco

    --Miguel A. Carrion se agrego cursor para validar si el afiliado posee un proveedor de odontologia 21/07/2020
    IF v_inser = pkg_const.c_serv_odontologicos THEN
    --
        OPEN c_proveedor(fonos_row.compania, fonos_row.ramo, fonos_row.secuencial, fonos_row.plan, v_inser);

        FETCH c_proveedor INTO v_proveedor;
        v_existe := c_proveedor%FOUND;
        CLOSE c_proveedor;

        IF NOT v_existe AND NOT valida_reclamante(fonos_row.afiliado) 
        THEN
            p_outnum1 := 2;
            return;
        END IF;
    --
    END IF;

    ---Miguel A. Carrion 14/01/2021 Se agrego condicion ya que los procesos busca la fecha de version real del afiliado cuando es basico o voluntario.
    IF fonos_row.plan = v_plan_pbs OR v_inser = v_servicio_altocosto THEN
        var_fec_ini := fdp_fecver_ac(fonos_row.compania, --:PRE_CERTIF.COM_POL,
                        fonos_row.ramo, --:PRE_CERTIF.RAM_POL,
                        fonos_row.secuencial, --:PRE_CERTIF.SEC_POL,
                        sysdate, fonos_row.asegurado, fonos_row.dependiente);
    ELSIF v_inser = dbaper.busca_parametro('GMM', fonos_row.compania) THEN
        /*Funcion para buscar la fecha de version para los afiliado bajo el servicio de Gmm Miguel A. Carrion 14/01/2021 */
        var_fec_ini := fdp_fecver(fonos_row.compania, fonos_row.ramo, fonos_row.secuencial, 
            sysdate, fonos_row.asegurado,fonos_row.dependiente, '');
    END IF;


    --SI AUN NO SE HA GENERADO UNA RECLAMACION TOMA EL SERVICIO DEL VALOR DIGITADO--
    --EN CASO CONTRARIO TOMA EL SERVICIO DE LA RECLAMACION YA INSERTADA--
    IF ( nvl(fonos_row.sec_rec, 0) = 0 ) THEN
        fonos_row.tip_ser := v_inser;
    END IF;

    --

    fonos_row.tip_cob := v_intip;
    fonos_row.cobertura := v_incob;
    var_tip_ser2 := fonos_row.tip_ser;

    --Enfoco mcarrion 12/02/2019
    --If ajustado por Fclark 21/Jun/21
    IF
        fonos_row.tip_ser = pkg_const.c_serv_odontologicos
        AND fonos_row.tip_rec IN ( 'MEDICO', 'NO_MEDICO' )
    THEN
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
        IF v_prov_capitado = pkg_const.c_activo
            AND nvl(v_prov_existe, 0) = 0
            AND nvl(v_nuevo, pkg_const.c_no) = pkg_const.c_no
        THEN
            p_outnum1 := 2;
            return;
        END IF;

        --If ajustado por Fclark 21/Jun/21
        IF fonos_row.tip_ser = pkg_const.c_serv_odontologicos
            AND fonos_row.tip_rec IN ( 'MEDICO', 'NO_MEDICO' )
        THEN
            OPEN cur_cat_prov;
            FETCH cur_cat_prov INTO
                v_proveedor,
                v_categoria;
            CLOSE cur_cat_prov;
        END IF;
    END IF;

    ---Enfoco mcarrion 12/02/2019
    --

    OPEN c_cobertura;
    FETCH c_cobertura INTO dummy;
    v_existe := c_cobertura%found;
    CLOSE c_cobertura;

    IF NOT v_existe THEN
        p_outnum1 := 1;
        return;
    END IF;


    error := f_buscar_datos_cobertura(fonos_row, var_tip_ser2, fonos_row.tip_cob, ser_sal_row.descripcion, tip_c_sal_row.
        descripcion, cob_sal_row.descripcion, no_m_cob_row.limite, no_m_cob_row.por_des);
    
    IF error is not null THEN
        p_outnum1 := 3;
        return;
    END IF;
    --<jdeveaux 18may2016>
    /*Procedimiento para validar si el prestador de servicios se encuentra en la red del plan basico si no esta en la red de la poliza voluntario.*/
    /*Si se da esta condicion, todas las validaciones posteriores de coberturas deben hacerse bajo la configuracion del plan basico (ramo, secuencial, plan)*/
    DECLARE
        red_voluntario     BOOLEAN;
        red_excepcion_odon BOOLEAN;
        red_pbs            BOOLEAN;
    BEGIN
        --Solo debe funcionar para las polizas voluntarias
        IF fonos_row.ramo = pkg_const.c_ramo_salud_local THEN
            --Valida si el proveedor pertenece a la red del plan voluntario
            red_voluntario := paq_matriz_validaciones.validar_plan_afiliado(fonos_row.plan, fonos_row.tip_ser, fonos_row.
            tip_rec, fonos_row.afiliado);

            ---MCARRION 26/06/2019
            red_excepcion_odon := dbaper.excepcion_poliza_odon(fonos_row.compania, fonos_row.ramo, fonos_row.secuencial,
            fonos_row.tip_ser);

            v_simultaneo := dbaper.paq_matriz_validaciones.valida_simultaneidad(fonos_row.asegurado, fonos_row.dependiente,
            fonos_row.compania);

            --Ajustado por FClark 21 Jun 22
            IF (
                v_simultaneo = pkg_const.c_si
                AND NOT ( red_voluntario OR red_excepcion_odon )
            ) OR (
                v_inser = v_servicio_altocosto
                AND v_simultaneo = pkg_const.c_si
            ) THEN
                    --Busca los datos de la poliza del plan basico
                IF ( valida_reclamante(fonos_row.afiliado) ) THEN
                    v_proveedor := NULL;
                END IF;

                --JD FOREBRA <TRANSPLANTE RENAL>
                IF F_PACIENTE_RENAL(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE) = 'S' 
                AND F_COBERTURA_RENAL(FONOS_ROW.COBERTURA) = 'S' THEN
                    v_inser := v_servicio_renal;
                    v_intip := F_TIP_COB_RENAL(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE);
                    FONOS_ROW.TIP_SER := V_INSER;
                    FONOS_ROW.TIP_COB := V_INTIP;
                END IF;
                /* Si el servicio es Alto Costo entonces busca la fecha de version del afiliado
                y la gradualidad segun las cotizaciones o aporte que tenga el afiliado
                    Miguel A. Carrion 14/01/2021  */
                IF v_inser = v_servicio_altocosto
                THEN
                    f_fec_ver := dbaper.fdp_fecver_ac(v_compania_pbs, v_ramo_pbs,
                            v_sec_pbs, fecha_dia, fonos_row.asegurado, nvl(fonos_row.dependiente, 0));
                    v_fec_final := add_months(f_fec_ver, 12);
                -- proceso para buscar lo consumido y disponible del afiliado
                    -- enviado como parametro para el servicio alto costo.
                    dbaper.pkg_admin_alto_costo.busca_disponible(v_compania_pbs, v_num_pla,  -- :p_num_pla     ,
                        NULL,  -- :p_nss         ,
                        fonos_row.asegurado,  -- :p_asegurado   ,
                        nvl(fonos_row.dependiente, 0),  -- :p_dependiente ,
                        v_fec_final,--:reclamac12.fec_ser                 ,  -- :p_fec_ser     ,
                        v_lim_ac,  -- :p_mon_max     ,
                        v_total_consumo,  -- :p_consumido   ,
                        v_bce_ac,    -- :p_disponible);
                        f_fec_ver, v_intip);

                    valor_max_ac := f_obtiene_mon_max_gradual(v_nss, fecha_dia, v_compania_pbs);
                    valor_max_ac := round(nvl(valor_max_ac, 0) - nvl(v_total_consumo, 0));

                    IF valor_max_ac <= 0 THEN
                        p_outnum1 := 4;
                        return;
                    END IF;
                END IF;
                ---Miguel A. Carrion 24/08/2020

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
    --JD FOREBRA <TRANSPLANTE RENAL>
    IF (F_PACIENTE_RENAL(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE) = 'S' 
        OR V_INSER = v_servicio_renal)
    AND F_COBERTURA_RENAL(FONOS_ROW.COBERTURA) = 'S' THEN
        v_inser := v_servicio_renal;
        v_intip := F_TIP_COB_RENAL(FONOS_ROW.ASEGURADO, FONOS_ROW.DEPENDIENTE);
        FONOS_ROW.TIP_SER := V_INSER;
        FONOS_ROW.TIP_COB := V_INTIP;
    END IF;
        

    /* Si el servicio es alto costo y el ramo es el ramo del basico, busca la fecha de version del afiliado
        y la gradualidad segun los aporte o cotizaciones  Miguel A. Carrion 14/01/2021   */
    IF fonos_row.ramo = v_ramo_pbs AND v_inser = v_servicio_altocosto
    THEN
        f_fec_ver := dbaper.fdp_fecver_ac(fonos_row.compania, -- :RECLAMAC12.COMPANIA,
            fonos_row.ramo, -- :RECLAMAC12.RAMO,
            fonos_row.secuencial, --:RECLAMAC12.SEC_POL,
            fecha_dia, fonos_row.asegurado,
            nvl(fonos_row.dependiente, 0));
        --
        v_fec_final := add_months(f_fec_ver, 12);
        --
        -- proceso para buscar lo consumido y disponible del afiliado
            -- enviado como parametro para el servicio alto costo.
        dbaper.pkg_admin_alto_costo.busca_disponible(fonos_row.compania, v_num_pla,  -- :p_num_pla     ,
            NULL,  -- :p_nss         ,
            fonos_row.asegurado,  -- :p_asegurado   ,
            nvl(fonos_row.dependiente, 0),  -- :p_dependiente ,
            v_fec_final,--:reclamac12.fec_ser                 ,  -- :p_fec_ser     ,
            v_lim_ac,  -- :p_mon_max     ,
            v_total_consumo,  -- :p_consumido   ,
            v_bce_ac,    -- :p_disponible);
            f_fec_ver, v_intip);

        valor_max_ac := f_obtiene_mon_max_gradual(v_nss, fecha_dia, fonos_row.compania);
        valor_max_ac := round(nvl(valor_max_ac, 0) - nvl(v_total_consumo, 0));

        IF valor_max_ac <= 0 THEN
            p_outnum1 := 4;
            return;
        END IF;
    END IF;
    ---Miguel A. Carrion 24/08/2020



    /* Si el servicio es Gmm, busca la fecha de version del afiliado y el limite y consumo
        Miguel A. Carrion 14/01/2021  */
    IF v_inser = dbaper.busca_parametro('GMM', fonos_row.compania) THEN
        f_fec_ver := dbaper.fdp_fecver(fonos_row.compania, fonos_row.ramo, fonos_row.secuencial, fecha_dia, fonos_row.
        asegurado, fonos_row.dependiente, '');

        --
        v_fec_final_gmm := add_months(f_fec_ver, 12);
        --

        var_tip_rec := substr(des_tip_n_med, 1, 10);
        p_lim_gmm(fonos_row.compania, fonos_row.ramo, fonos_row.secuencial, fonos_row.plan, fonos_row.tip_ser,
                    var_tip_rec, var_tip_a_uso, valor_max_gmm, fecha_dia, 'N',
                    fonos_row.asegurado, nvl(fonos_row.dependiente, 0), NULL, v_notas, fonos_row.fec_nac);

        balance_gmm := fdp_balance(fonos_row.asegurado, nvl(fonos_row.dependiente, 0), fonos_row.tip_ser, f_fec_ver, v_fec_final_gmm,
        fecha_dia,
                                    fonos_row.compania, fonos_row.ramo, fonos_row.secuencial);

        valor_max_gmm := round(nvl(valor_max_gmm, 0) - nvl(balance_gmm, 0), 2);

        IF valor_max_gmm <= 0 THEN
            p_outnum1 := 4;
            return;
        END IF;
    END IF;
    ---Miguel A. Carrion 24/08/2020

        /* Funcion que valida si el afiliado tiene una pre_certificacion vigente Miguel A. Carrion 19/07/2021*/
    v_secuencial_precert := nvl(dbaper.f_valida_precertif_fech_dupl(fonos_row.tip_rec, fonos_row.afiliado, var_tip_a_uso,
                                cod_ase, cod_dep, v_inser, fonos_row.cobertura), 0);

    dbms_output.put_line('V_Secuencial_precert->:  ' || v_secuencial_precert);
    IF v_secuencial_precert != 0 THEN
        p_outnum1 := 2;
        p_outnum2 := v_secuencial_precert;
        return;
    END IF;
    -- Fin Miguel A. Carrion 06/05/2021


    -- Enfoco - 05/11/2018
    paq_matriz_validaciones.busca_rangos_cobertura(fonos_row.plan, fonos_row.tip_ser, fonos_row.tip_cob, p_ran_u_exc,
    p_ran_u_max);
    /* ---------------------------------------------------------------------- */
    /*   Determina Origen de la Cobertura                                     */
    /* ---------------------------------------------------------------------- */
    --
    OPEN c_plan_exception;
    FETCH c_plan_exception INTO m_plan_exception;
    CLOSE c_plan_exception;
    --
    OPEN c_valida_plan_excento(fonos_row.plan, m_plan_exception);
    FETCH c_valida_plan_excento INTO m_valida_plan;
    v_existe := c_valida_plan_excento%found;
    CLOSE c_valida_plan_excento;

    IF NOT v_existe AND 
        NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, 
            fonos_row.ramo, fonos_row.secuencial, fonos_row.plan, fonos_row.tip_ser,
            fonos_row.tip_cob, fonos_row.cobertura, fonos_row.tip_rec, fonos_row.afiliado,
            vusuario) THEN
                
        ori_flag := paq_matriz_validaciones.busca_origen_cob(fonos_row.tip_ser, 
                    fonos_row.tip_cob, fonos_row.cobertura, vusuario, 
                    fonos_row.ramo,fonos_row.compania);

        IF ori_flag is not null THEN
            p_outnum1 := 2;
            return;
        END IF;
        
        -- Htorres - 29/09/2019
        -- Monto máximo que se pueda otorgar para esa cobertura por canales
        vmon_max_cob_origen := f_busca_origen_cob_mon_max(fonos_row.tip_ser, 
        fonos_row.tip_cob, fonos_row.cobertura, vusuario);
    
    END IF;

    /* ----------------------------------------------------------------------*/
    /* --------------------------------------------------------------------- */
    /*  Busca Limite de monto por cobertura de salud                         */
    /* --------------------------------------------------------------------- */

    /* If..End if adicionado para condicionar si la poliza esta exento
        de restriccion.  Roche Louis/TECHNOCONS. d/f 17-Dic-2009 8:57am
    */
    IF NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, fonos_row.ramo, fonos_row.
        secuencial, fonos_row.plan, fonos_row.tip_ser,
        fonos_row.tip_cob, fonos_row.cobertura, fonos_row.
        tip_rec, fonos_row.afiliado, vusuario) THEN

        limite_laboratorio := paq_matriz_validaciones.tip_cob_mon_max(
            fonos_row.compania, fonos_row.ramo, fonos_row.
            secuencial, fonos_row.plan, fonos_row.tip_ser,
            fonos_row.tip_cob, p_mon_exe, p_uni_t_exe,
            p_ran_exe, p_por_coa,
            p_uni_t_max);
    END IF;
        --
        --P_MON_DED_TIP_COB);
        /* --------------------------------------------------------------------- */
        /* Valida que el Asegurado puede Recibir la Cobertura de Salud.          */
        /* --------------------------------------------------------------------- */
    error := paq_matriz_validaciones.chk_cobertura_asegurado_fono(
            true, fonos_row.tip_rec, fonos_row.afiliado,
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
            pla_stc_row.exc_mca, pla_stc_row.mon_ded, v_categoria,
            v_proveedor);

    dbms_output.put_line('CHK_COBERTURA_ASEGURADO_FONO:  ' || error);
    IF error is not null THEN
        p_outnum1 := 2;
        return;
    END IF;

    /*---------------------------------------------------------- */
    /* Valida que no se este digitando una Reclamacion           */
    /* que ya fue reclamada por el mismo.                        */
    /* --------------------------------------------------------- */
    sec_reclamacion := paq_matriz_validaciones.valida_rec_fecha_null(true, var_estatus_can, nvl(fonos_row.
        ano_rec, to_char(fecha_dia, 'YYYY')), --Se le agreo el nvl Para en caso que el ano llegue null Tome el ano de la fecha del dia Miguel A. Carrion 18/08/2021 FCCM
        fonos_row.compania, nvl(v_ramo_ori, fonos_row.ramo),-- FONOS_ROW.RAMO,      -- V_RAMO_ORI Reclamaciones Duplicadas (Victor Acevedo)  /*Se le agreo NVL para que tome el ramo de la sesion, ya que la variable viene Nula Miguel A. Carrion 18/08/2021 FCCM*/
        fonos_row.sec_rec, fonos_row.tip_rec, fonos_row.afiliado, 
        var_tip_a_uso,cod_ase, cod_dep, fonos_row.tip_ser, fonos_row.
        tip_cob, fonos_row.cobertura,fecha_dia);

    IF sec_reclamacion is not null THEN
        p_outnum1 := 2;
        return;
    END IF;

    /* ---------------------------------------------------------- */
    /* Valida que no se este digitando una Reclamacion            */
    /* que ya fue reclamada por otro que participo en la          */
    /* aplicacion de la Cobertura.                                */
    /* ---------------------------------------------------------- */
    error := paq_matriz_validaciones.valida_rec_c_sal_fec(
        true, var_estatus_can, fonos_row.ano_rec, fonos_row.
        compania, fonos_row.ramo,
        fonos_row.sec_rec, fonos_row.tip_rec, fonos_row.
        afiliado, var_tip_a_uso, cod_ase,
        cod_dep, fonos_row.tip_ser, fonos_row.tip_cob,
        fonos_row.cobertura, fecha_dia);

    IF error is not null THEN
        p_outnum1 := 2;
        return;
    END IF;

    /* ---------------------------------------------------------- */
    /* Valida:                                                    */
    /* 1-) Tiempo de Espera de la Cobertura                       */
    /* ---------------------------------------------------------- */
    error := paq_matriz_validaciones.validar_tiempo_espera(
        true, fecha_dia, fonos_row.fec_ing, pla_stc_row.tie_esp, 
        pla_stc_row.uni_tie_t);
    
    IF error is not null and error != '0' THEN
        p_outnum1 := 2;
        return;
    END IF;
    -- Caso # 14282
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
    fonos_row.tip_cob, fonos_row.cobertura,
    fonos_row.tip_rec, fonos_row.afiliado,
    vusuario) THEN
        error := paq_matriz_validaciones.validar_frec_tip_cob(true, var_estatus_can, var_tip_a_uso,
        cod_ase, cod_dep,
                                                                fonos_row.plan, fonos_row.tip_ser,
                                                                fonos_row.tip_cob, fonos_row.cobertura,
                                                                fecha_dia,
                                                                var_fec_ini, fonos_row.compania,
                                                                fonos_row.ramo, fonos_row.secuencial,
                                                                dsp_cob_lab,
                                                                dsp_frec_tip_cob);
    END IF;

    IF error is not null THEN
        p_outnum1 := 2;
        return;
    END IF;

    /* ---------------------------------------------------------- */
    /* Valida que en las Reclamaciones:                           */
    /* 1-) Cobertura No Exceda la Frecuencia de Uso               */
    /* 2-) Cobertura No Exceda los Montos Maximo.                 */
    /* ---------------------------------------------------------- */
    IF NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, fonos_row.
            ramo, fonos_row.secuencial, fonos_row.plan, fonos_row.tip_ser,
                                                                fonos_row.tip_cob, fonos_row.
                                                                cobertura, fonos_row.tip_rec,
                                                                fonos_row.afiliado, vusuario)
                                                                THEN
        dbms_output.put_line('PLA_STC_ROW.FRECUENCIA:  ' || pla_stc_row.frecuencia);
        dbms_output.put_line('PLA_STC_ROW.UNI_TIE_T: ' || pla_stc_row.uni_tie_t);
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

        dbms_output.put_line('Validar_Frec_Cobertura:  ' || error);
        --
    END IF;
    IF error is not null THEN
        p_outnum1 := 2;
        return;
    END IF;
    /* ---------------------------------------------------  */
    /* Determina el limite de frecuencia paralelo           */
    /* por plan por tipo de cobertura                       */
    /* ---------------------------------------------------  */
    IF NOT paq_matriz_validaciones.f_poliza_exento_restriccion(fonos_row.compania, fonos_row.
        ramo, fonos_row.secuencial, fonos_row.plan, fonos_row.tip_ser,
        fonos_row.tip_cob, fonos_row.
        cobertura, fonos_row.tip_rec,
        fonos_row.afiliado, vusuario)
    THEN
        dbms_output.put_line('var_frecuencia->:  ' || var_frecuencia);
        dbms_output.put_line('VAR_FEC_INI->:  ' || var_fec_ini);
        dbms_output.put_line('FONOS_ROW.PLAN->:  ' || fonos_row.plan);
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

        dbms_output.put_line('validar_frec_tip_cob_fono:  ' || error);
        dbms_output.put_line('var_dsp_frec_acum->:  ' || var_dsp_frec_acum);
    END IF;
    
    IF error is not null THEN
        p_outnum1 := 2;
        return;
    END IF;
    
    /* ---------------------------------------------------  */
    /* Determina si el afiliado digita el Monto a Reclamar  */
    /* para igualar el limite al monto digitado             */
    /* ---------------------------------------------------  */
    --VIA FONOSALUD EL AFILIADO NO DIGITA NINGUN MONTO A RECLAMAR--
    --VIA POS EL AFILIADO DIGITA EL MONTO A RECLAMAR--
    --
    fonos_row.mon_rec_afi := NULL; --Se limpia la variable ya que se quedaba sucia Miguel A.Carrion 26/10/2021
    IF nvl(to_number(p_instr2), 0) > 0 THEN
        IF fonos_row.tip_ser = v_serv_eme THEN -- Se coloco esta condicion para los servicios de Emergencia Miguel A. Carrion 21/10/2021
            fonos_row.mon_rec_afi := nvl(to_number(p_instr2), 0);
        ELSE
            IF nvl(to_number(p_instr2), 0) < no_m_cob_row.limite THEN
                fonos_row.mon_rec_afi := to_number(p_instr2);
            ELSE
                fonos_row.mon_rec_afi := no_m_cob_row.limite;
            END IF;
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
    IF p_mon_exe IS NOT NULL AND p_mon_exe <> 0
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
        mon_pag, fonos_row.mon_ded,p_mon_exe, p_mon_acum);

    IF fonos_row.tip_ser = v_serv_eme THEN
        -- Funcio para buscar el monto maximo parametrizado para una cobertura X Miguel A. Carrion FCCM 15/10/2021
        BEGIN
            v_monto_cober := NULL;
            v_monto_cober := f_valida_monto_cobertura_web(fonos_row.cobertura, fonos_row.
            compania);
        EXCEPTION
            WHEN OTHERS THEN
                v_error := sqlcode;
                v_desc_error := substr(sqlerrm, 1, 1000);

        END;
            /*Condicion para validar que el monto a pagar de la cobertura no sea mayor al monto parametrizado Miguel A. Carrion 14/10/2021*/
        IF
            fonos_row.mon_pag > v_monto_cober
            AND f_valida_eme_cobertura_web(fonos_row.cobertura, fonos_row.compania)
        THEN
            dbms_output.put_line(' Entro validacion emergencia:-> ');
            p_outnum1 := 5;
            return;
        END IF;

    END IF;


        /* Si el servicio es Alto costo, valida si el asegurado llego al tope de los 2 salario minimo y le otorga el porciento
            de cobertura al 100%, de no ser asi le otorga segun lo que tenga acumulado de co-pago Miguel A. Carrion 24/08/2020  */
    IF v_inser = v_servicio_altocosto THEN
        dbaper.p_limitar_copago_x_grupo_ac(fonos_row.compania, fonos_row.ramo, fonos_row.
            secuencial, fonos_row.plan, nvl(v_intip, fonos_row.tip_cob), var_tip_a_uso,
            fonos_row.asegurado, nvl(fonos_row.dependiente, 0), fecha_dia, fonos_row.
            mon_ded, fonos_row.mon_pag, v_simultaneo,
            fonos_row.mon_ded, fonos_row.mon_pag);
    END IF;

    /* Si el servicio es GMM le asgina el monto correspondiente segun su limite   Miguel A. Carrion 24/08/2020   */
    IF v_inser = dbaper.busca_parametro('GMM', fonos_row.compania)
        AND fonos_row.mon_pag > valor_max_gmm
    THEN
        fonos_row.mon_ded := fonos_row.mon_ded + ( fonos_row.mon_pag - valor_max_gmm );
        fonos_row.mon_pag := valor_max_gmm;
    END IF;
    monto_laboratorio := 0;
    IF limite_laboratorio IS NOT NULL
        AND limite_laboratorio <> 0
    THEN
        -- Si tiene limite monto maximo por tipo de cobertura, 
        ---entonces procede a buscar monto acumulado  --
        t_fec_ini := paq_matriz_validaciones.determina_fecha_rango(fecha_dia, var_fec_ini,
            NULL, NULL, NULL,p_ran_u_exc, limite_laboratorio,nvl(p_uni_t_max,365));
        /* ----------------------------------------------------------------------  */
        /* Obtiene la Fecha Final segun la Unidad de Tiempo de monto maximo  */
        /* para determinar si ha excedido el Uso maximo de la Cobertura.          */
        /* ----------------------------------------------------------------------  */
        t_fec_fin := paq_matriz_validaciones.determina_fecha_rango_fin(fecha_dia,
            var_fec_ini, NULL, NULL, NULL,limite_laboratorio,nvl(p_uni_t_max, 365), p_ran_u_exc);
        /* Si la Fecha Fin es null, entonces sera igual */
        /* a la Fecha de Servicio.     */
        IF t_fec_fin IS NULL THEN t_fec_fin := fecha_dia; END IF;
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
        monto_laboratorio := monto_laboratorio + fonos_row.mon_pag;
        IF monto_laboratorio > limite_laboratorio THEN
            p_outnum1 := 2;
            return;
        END IF;
    END IF; /*END LIMITE_LABORATORIO IS NOT NULL*/

    -- Htorres - 29/09/2019
    -- Monto máximo que se pueda otorgar para esa cobertura por canales
    IF nvl(vmon_max_cob_origen, 0) > 0
        AND ( fonos_row.mon_pag > vmon_max_cob_origen )
    THEN
        p_outnum1 := 2;
        return;
    END IF;

    
    /***************************************************/
    /*    Validar que el afiliado pueda reclamar en el plan del asegurado */
    /***************************************************/

    IF fonos_row.tip_ser != pkg_const.c_serv_odontologicos THEN
        v_puede_dar_servicio := paq_matriz_validaciones.validar_plan_afiliado(fonos_row.plan,
        fonos_row.tip_ser, fonos_row.tip_rec, fonos_row.afiliado);
    ELSE
        cat_plan_odon := validar_plan_afiliado_cat(fonos_row.plan, fonos_row.
        tip_ser, fonos_row.tip_rec, fonos_row.afiliado, v_categoria,
                                                    v_proveedor, fonos_row.compania);

        IF
            NOT ( cat_plan_odon )
            AND ( NOT valida_reclamante(fonos_row.afiliado) )
        THEN

            v_puede_dar_servicio := false;
        ELSIF ( nvl(v_simultaneo, 'N') = 'S' OR fonos_row.plan = v_plan_pbs ) THEN
            v_puede_dar_servicio := true;
        END IF;

    END IF;

    ---MCARRION 26/06/2019
    red_excepcion_odon := dbaper.excepcion_poliza_odon(fonos_row.compania, fonos_row.
    ramo, fonos_row.secuencial, fonos_row.tip_ser);


    IF (cat_plan_odon AND fonos_row.tip_ser = pkg_const.c_serv_odontologicos) 
        or red_excepcion_odon 
    THEN
        v_puede_dar_servicio := true;

    END IF;

    IF not v_puede_dar_servicio THEN
        p_outnum1 := 2;
        return;
    END IF;

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

    IF error is not null THEN
        p_outnum1 := 2;
        return;
    END IF;

    /***************************************************/
    /*    Validar Beneficio Maximo por Familia         */
    /***************************************************/
    v_excede_monto_maximo := paq_matriz_validaciones.validar_beneficio_max(fonos_row.
    compania, fonos_row.ramo, fonos_row.secuencial, fonos_row.plan, cod_ase,
                                                            fecha_dia,
                                                            var_fec_ini,
                                                            fonos_row.
                                                            fec_ing, fonos_row.
                                                            mon_pag, NULL);

    IF v_excede_monto_maximo THEN
        p_outnum1 := 2;
        return;
    END IF;
    /* --------------------------------------------- */
    /* Valida que el Monto Maximo digitado no exceda */
    /* el especificado en la Cobertura, solo para farmacias. */
    /* --------------------------------------------- */
    IF (fonos_row.mon_rec_afi IS NOT NULL AND fonos_row.mon_rec_afi <> 0)
        AND (pla_stc_row.mon_max IS NOT NULL AND pla_stc_row.mon_max <> 0 )
        AND ( nvl(dsp_mon_pag_acum, 0) + fonos_row.mon_pag ) >= pla_stc_row.mon_max
    THEN

            fonos_row.mon_rec_afi := pla_stc_row.mon_max - dsp_mon_pag_acum;
            p_outnum1 := 2;
            return;
    END IF;

    var_code := 0;

    -- Victor Acevedo / TECHNOCONS.
    -- Para verificar si no hay ningun error
    -- VALIDAR_COBERTURA: Funcion para controlar la cobertura 2836 ------------------------------
    -- * Esta cobertura solo estará disponible en horario de 6:00 pm a 6:00 am
    -- * Las clínicas paquetes no deben reclamar por esta cobertura
    -- * Los médicos categoría A+ (Platinum) están excepto de estas validaciones
    -- * Las excepciones deben poder ser manejadas por un superusuario
    -- * Para que el médico pueda reclamar el servicio el asegurado debe tener
    --   una reclamación del mismo servicio (EMERGENCIA) por lo menos de 72 horas de antelación.
    --------------------------------------------------------------------------------------------- 
    IF fonos_row.tip_ser <> pkg_const.c_ser_emergencia THEN
        -- SERVICIO DE EMERGENCIA
        -- Suspencion por Suplantacion (Fraude)
        mfraude := 'N';

        -- para verificar si el afiliado tiene una marca de suspencion del servicio de salud
        OPEN c_fraude;
        FETCH c_fraude INTO mfraude;
        CLOSE c_fraude;
        IF mfraude = 'S' THEN
            p_outnum1 := 2;
            return;
        END IF;
        -- Fraude
    END IF;

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
        mon_ded = fonos_row.mon_ded,
        coberturastr = p_instr1
     WHERE
            numsession = p_numsession;

    p_outstr1 := ltrim(to_char(fonos_row.mon_pag, '999999990.00'));
    p_outstr2 := ltrim(to_char(fonos_row.mon_ded, '999999990.00'));
    p_outnum1 := var_code;

END;