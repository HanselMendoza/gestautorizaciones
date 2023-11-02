--------------------------------------------------------
--  DDL for Procedure P_OPEN_PRECERTIF
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OPEN_PRECERTIF" (
    p_numsession IN NUMBER,
    p_outstr1    OUT VARCHAR2,
    p_outstr2    OUT VARCHAR2,
    p_outnum1    OUT NUMBER
) IS

    fecha_dia       DATE;
    var_code        NUMBER(2) := 1;
    sec_precertif   NUMBER;
    vnum_ingreso    NUMBER;
    var_ano_rec     NUMBER := to_number(to_char(sysdate, 'YYYY'));
    var_pre_fijo    NUMBER := 7;
    var_estatus     NUMBER := 734; -- Pre-Certifiacion Aperturada
    var_reclamante  NUMBER(14);
    var_asegurado   VARCHAR2(15);
    var_dependiente VARCHAR2(3);
    var_compania    NUMBER(2);
    var_ramo        NUMBER(2);
    var_secuencial  NUMBER(7);
    var_plan        NUMBER(3);
    var_tip_rec     VARCHAR2(10);
    var_tip_ser     NUMBER(2);
    var_tip_a_uso   VARCHAR2(10);
    var_ase_uso     NUMBER(11);
    var_dep_uso     NUMBER(3);
    var_med_tra     NUMBER(7);
    var_rie_lab     VARCHAR2(1);
    var_num_pla     VARCHAR2(20);
    var_tip_cob     NUMBER(3);
    CURSOR c IS
    SELECT
        afiliado,
        asegurado,
        dependiente,
        compania,
        ramo,
        secuencial,
        plan,
        tip_rec,
        tip_ser,
        med_tra,
        rie_lab,
        ase_carnet,
        tip_cob
    FROM
        infox_session
    WHERE
        numsession = p_numsession
    FOR UPDATE;

    vusuario        VARCHAR2(15) := nvl(dbaper.f_busca_usu_registra_canales(user), 'FONOSALUD');
BEGIN
    fecha_dia := to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
    var_ano_rec := to_char(sysdate, 'YYYY');
      --
    OPEN c;
    FETCH c INTO
        var_reclamante,
        var_asegurado,
        var_dependiente,
        var_compania,
        var_ramo,
        var_secuencial,
        var_plan,
        var_tip_rec,
        var_tip_ser,
        var_med_tra,
        var_rie_lab,
        var_num_pla,
        var_tip_cob;

    IF c%found THEN
        -- Genera secuencia Pre-Certificaci�n
        sec_precertif := pkg_pre_certificaciones.f_get_secuencial('PRE_CERTIFICACION');
        vnum_ingreso := pkg_pre_certificaciones.f_secuencia_prefijo('PRE_CERTIFICACION', var_ano_rec, sec_precertif);
        --
        var_ase_uso := to_number(var_asegurado);
        var_dep_uso := to_number(var_dependiente);
        --
        IF nvl(var_dep_uso, 0) > 0 THEN
            var_tip_a_uso := 'DEPENDIENT';
        ELSE
            var_tip_a_uso := 'ASEGURADO';
            var_dep_uso := 0;
        END IF;

        INSERT INTO pre_certificacion (
            ano,
            secuencial,
            num_precert,
            com_pol,
            ram_pol,
            sec_pol,
            pla_pol,
            tip_rec,
            no_medico,
            tip_p_hos,
            per_hos,
            fec_ing,
            fec_tra,
            usu_ing,
            estatus,
            servicio,
            motivo_estatus,
            dep_uso,
           --FEC_SAL,
            med_tra,
            coment,
            rie_lab,
            num_pla,
            pre_fijo,
            for_pro
        ) VALUES (
            var_ano_rec,
            sec_precertif,
            vnum_ingreso,
            var_compania,
            var_ramo,
            var_secuencial,
            var_plan,
            var_tip_rec,
            var_reclamante,
            var_tip_a_uso,
            var_ase_uso,
            fecha_dia,
            sysdate,
            vusuario,
            var_estatus,
            var_tip_ser,
            NULL,
            var_dep_uso,
           --FECHA_DIA,
            var_med_tra,
            'PRE-CERTIFICACION VIA ' || vusuario,
            var_rie_lab,
            var_num_pla,
            var_pre_fijo,
            'NORMAL'
        );

        var_code := 0;
        UPDATE infox_session
        SET
            code = var_code,
            ano_rec = var_ano_rec,
            sec_rec = sec_precertif,
            reclamacion = ltrim(to_char(sec_precertif))
        WHERE
            CURRENT OF c;

    END IF;

    CLOSE c;
    p_outnum1 := var_code;
    p_outstr1 := sec_precertif;
    p_outstr2 := var_ramo;
END;
