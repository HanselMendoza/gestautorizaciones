--------------------------------------------------------
--  DDL for Procedure P_INGRESO_FROM_RECLAMAC
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_INGRESO_FROM_RECLAMAC" (
    p_numsession IN NUMBER
) IS
    -- Proceso para crear un Ingreso a partir de una Reclamacion dada
    -- Creado por Htorres para Enfoco - 28/07/2019

    fonos_row           infox_session%rowtype;
    vsecuencia          NUMBER := 0;
    vcob_row            rec_c_sal%rowtype;
    vnum_ingreso        NUMBER;
    vest_rep_convertida rep_hos.estatus%TYPE := 60;
    vservicio_param     VARCHAR2(256) := f_obten_parametro_seus('ING_FROM_REC_TIP_SER');
    var_ano             NUMBER(4) := to_char(sysdate, 'YYYY');
    CURSOR a IS
    SELECT
        ano_rec,
        compania,
        ramo,
        sec_rec,
        tip_ser
    FROM
        infox_session
    WHERE
        numsession = p_numsession;

    CURSOR rec_c IS
    SELECT
        ano,
        compania,
        ramo,
        secuencial,
        sec_pol,
        plan,
        usu_ing,
        fec_ape,
        fec_tra,
        fec_ser,
        tip_rec,
        reclamante,
        tip_a_uso,
        ase_uso,
        dep_uso,
        num_pla,
        tip_ser,
        rie_lab,
        cau_no_simult,
        tip_r_lab,
        fec_con,
        usu_con,
        ano_precert,
        num_precert,
        canal
    FROM
        reclamacion
    WHERE
            ano = fonos_row.ano_rec
        AND compania = fonos_row.compania
        AND ramo = fonos_row.ramo
        AND secuencial = fonos_row.sec_rec
        AND estatus = pkg_const.e_reclamacion_vigente -- APERTURADA VIA TELEF.
        AND sec_r_hos IS NULL;

    vreclamac_row       rec_c%rowtype;
    CURSOR cob_c IS
    SELECT
        servicio,
        tip_cob,
        cobertura,
        frecuencia,
        mon_rec,
        reserva,
        61                       estatus,
        lim_afi,
        tip_rec,
        reclamante,
        coment,
        por_coa,
        por_des,
        mon_pag,
        ram_pol,
        sec_pol,
        mon_sim,
        mon_coaseg,
        nvl(excedente_copago, 0) excedente_copago
    FROM
        reclamacion_cobertura_salud
    WHERE
            ano = fonos_row.ano_rec
        AND compania = fonos_row.compania
        AND ramo = fonos_row.ramo
        AND secuencial = fonos_row.sec_rec
    ORDER BY
        secuencia;

BEGIN
    OPEN a;
    FETCH a INTO
        fonos_row.ano_rec,
        fonos_row.compania,
        fonos_row.ramo,
        fonos_row.sec_rec,
        fonos_row.tip_ser;

    IF a%found THEN
        IF instr(vservicio_param, fonos_row.tip_ser) > 0 THEN
          --
            OPEN rec_c;
            FETCH rec_c INTO vreclamac_row;
            IF rec_c%found THEN
            -- Genera secuencias del ingreso
                vnum_ingreso := dbaper.paq_reclamacion.p_secuencia_reclamacion('REP_HOS');
                vreclamac_row.canal := pkg_pre_certificaciones.f_obten_canal_aut(vreclamac_row.usu_ing);
            --
                INSERT INTO reporte_hospitalizacion (
                    ano,
                    secuencial,
                    tip_rec,
                    no_medico,
                    tip_p_hos,
                    per_hos,
                    dep_uso,
                    com_pol,
                    ram_pol,
                    sec_pol,
                    pla_pol,
                    servicio,
                    fec_ing,
                    estatus,
                    fec_tra,
                    usu_ing,
                    fecha_alta,
                    fec_sal,
                    usu_sal,
                    rie_lab,
                    cau_no_simult,
                    for_pro,
                    tip_r_lab,
                    num_pla,
                    ano_rec,
                    sec_rec,
                    ano_precert,
                    num_precert,
                    canal
                ) VALUES (
                    vreclamac_row.ano,
                    vnum_ingreso,
                    vreclamac_row.tip_rec,
                    vreclamac_row.reclamante,
                    vreclamac_row.tip_a_uso,
                    vreclamac_row.ase_uso,
                    vreclamac_row.dep_uso,
                    vreclamac_row.compania,
                    vreclamac_row.ramo,
                    vreclamac_row.sec_pol,
                    vreclamac_row.plan,
                    vreclamac_row.tip_ser,
                    vreclamac_row.fec_ser,
                    vest_rep_convertida,
                    vreclamac_row.fec_tra,
                    vreclamac_row.usu_ing,
                    vreclamac_row.fec_tra,
                    vreclamac_row.fec_tra,
                    vreclamac_row.usu_ing,
                    vreclamac_row.rie_lab,
                    vreclamac_row.cau_no_simult,
                    'NORMAL',
                    vreclamac_row.tip_r_lab,
                    vreclamac_row.num_pla,
                    vreclamac_row.ano,
                    vreclamac_row.secuencial,
                    vreclamac_row.ano_precert,
                    vreclamac_row.num_precert,
                    vreclamac_row.canal
                );
            --
                OPEN cob_c;
                LOOP
                    FETCH cob_c INTO
                        vcob_row.servicio,
                        vcob_row.tip_cob,
                        vcob_row.cobertura,
                        vcob_row.frecuencia,
                        vcob_row.mon_rec,
                        vcob_row.reserva,
                        vcob_row.estatus,
                        vcob_row.lim_afi,
                        vcob_row.tip_rec,
                        vcob_row.reclamante,
                        vcob_row.coment,
                        vcob_row.por_coa,
                        vcob_row.por_des,
                        vcob_row.mon_pag,
                        vcob_row.ram_pol,
                        vcob_row.sec_pol,
                        vcob_row.mon_sim,
                        vcob_row.mon_coaseg,
                        vcob_row.excedente_copago;

                    EXIT WHEN cob_c%notfound;
              --
                    vsecuencia := vsecuencia + 1;
              --
                    INSERT INTO rep_h_cob (
                        ano,
                        secuencial,
                        secuencia,
                        servicio,
                        tip_cob,
                        cobertura,
                        fec_ser,
                        frecuencia,
                        mon_rec,
                        reserva,
                        estatus,
                        lim_afi,
                        tip_afi,
                        afi_rec,
                        coment,
                        por_coa,
                        por_des,
                        mon_pag,
                        com_pol,
                        ram_pol,
                        sec_pol,
                        mon_sim,
                        mon_coaseg,
                        excedente_copago,
                        fec_ing_cob,
                        usu_ing_cob
                    ) VALUES (
                        vreclamac_row.ano,
                        vnum_ingreso,
                        vsecuencia,
                        vcob_row.servicio,
                        vcob_row.tip_cob,
                        vcob_row.cobertura,
                        vreclamac_row.fec_ser,
                        vcob_row.frecuencia,
                        vcob_row.mon_rec,
                        vcob_row.reserva,
                        vcob_row.estatus,
                        vcob_row.lim_afi,
                        vcob_row.tip_rec,
                        vcob_row.reclamante,
                        vcob_row.coment,
                        vcob_row.por_coa,
                        vcob_row.por_des,
                        vcob_row.mon_pag,
                        vreclamac_row.compania,
                        vreclamac_row.ramo,
                        vcob_row.sec_pol,
                        vcob_row.mon_sim,
                        vcob_row.mon_coaseg,
                        vcob_row.excedente_copago,
                        vreclamac_row.fec_tra,
                        vreclamac_row.usu_ing
                    );
              --
                END LOOP;

                CLOSE cob_c;
            END IF;

            CLOSE rec_c;
          -- Relaciona reclamacion con ingreso
            UPDATE reclamacion
            SET
                ano_r_hos = vreclamac_row.ano,
                sec_r_hos = vnum_ingreso
            WHERE
                    ano = fonos_row.ano_rec
                AND compania = fonos_row.compania
                AND ramo = fonos_row.ramo
                AND secuencial = fonos_row.sec_rec;
          --
        END IF;
    END IF;

    CLOSE a;
END;
