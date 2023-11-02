--------------------------------------------------------
--  DDL for Procedure P_INSERTCOBERTURA_PRECERTIF
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_INSERTCOBERTURA_PRECERTIF" (
    p_numsession IN NUMBER,
    p_outnum1    OUT NUMBER
) IS
BEGIN
    DECLARE
        fonos_row      infox_session%rowtype;
        fecha_dia      DATE;
        var_code       NUMBER(2) := 1;
        var_reclamante NUMBER(14);
        var_tip_rec    VARCHAR2(10);
        var_tip_ser    NUMBER(2);
        var_tip_cob    NUMBER(3);
        var_cobertura  NUMBER(5);
        var_mon_rec    NUMBER(11, 2);
        var_fec_ser    DATE;
        var_estatus    NUMBER(3) := 61;
        var_secuencia  NUMBER(7);
        var_mon_pag    NUMBER(11, 2);
        var_mon_ded    NUMBER(11, 2);
        var_por_coa    NUMBER(11, 2);
        var_mon_coa    NUMBER(11, 2);
        CURSOR a IS
        SELECT
            fec_ing
        FROM
            pre_certificacion
        WHERE
                ano = fonos_row.ano_rec
            AND com_pol = fonos_row.compania
            AND ram_pol = fonos_row.ramo
            AND secuencial = fonos_row.sec_rec;

        CURSOR b IS
        SELECT
            nvl(MAX(secuencia), 0) + 1
        FROM
            pre_c_cob
        WHERE
                ano = fonos_row.ano_rec
            AND com_pol = fonos_row.compania
            AND ram_pol = fonos_row.ramo
            AND secuencial = fonos_row.sec_rec;

        CURSOR c IS
        SELECT
            tip_rec,
            afiliado,
            tip_ser,
            tip_cob,
            cobertura,
            ano_rec,
            compania,
            ramo,
            secuencial,
            sec_rec,
            mon_rec,
            mon_pag,
            mon_ded,
            por_coa
        FROM
            infox_session
        WHERE
            numsession = p_numsession;

        vusuario       VARCHAR2(15) := nvl(dbaper.f_busca_usu_registra_canales(user), 'FONOSALUD');
    BEGIN
        fecha_dia := to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
        OPEN c;
        FETCH c INTO
            var_tip_rec,
            var_reclamante,
            var_tip_ser,
            var_tip_cob,
            var_cobertura,
            fonos_row.ano_rec,
            fonos_row.compania,
            fonos_row.ramo,
            fonos_row.secuencial,
            fonos_row.sec_rec,
            var_mon_rec,
            var_mon_pag,
            var_mon_ded,
            var_por_coa;

        IF c%found THEN
            OPEN a;
            FETCH a INTO var_fec_ser;
            IF a%found THEN
                OPEN b;
                FETCH b INTO var_secuencia;
                CLOSE b;
                var_mon_coa := var_mon_rec - var_mon_pag;
                BEGIN
                    INSERT INTO pre_c_cob (
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
                        por_coa,
                        por_des,
                        mon_pag,
                        com_pol,
                        ram_pol,
                        sec_pol,
                        mon_coaseg,
                        excedente_copago,
                        fec_ing_cob,
                        usu_ing_cob,
                        fec_tra,
                        usu_tra
                    ) VALUES (
                        fonos_row.ano_rec,
                        fonos_row.sec_rec,
                        var_secuencia,
                        var_tip_ser,
                        var_tip_cob,
                        var_cobertura,
                        var_fec_ser,
                        1, -- FREC
                        var_mon_rec,
                        var_mon_rec,
                        var_estatus,
                        var_mon_rec,
                        var_tip_rec,
                        var_reclamante,
                        var_por_coa,
                        0, -- POR_DES
                        var_mon_pag,
                        fonos_row.compania,
                        fonos_row.ramo,
                        fonos_row.secuencial,
                        var_mon_coa,
                        var_mon_ded,
                        sysdate,
                        vusuario,
                        sysdate,
                        vusuario
                    );

            --ACUMULAR CAMPO TOT_MON_DED--
                    UPDATE infox_session
                    SET
                        tot_mon_ded = nvl(tot_mon_ded, 0) + nvl(var_mon_ded, 0)
                    WHERE
                        numsession = p_numsession;

                    var_code := 0;
          /*EXCEPTION
            WHEN OTHERS THEN
              VAR_CODE := 1;*/
                END;

            ELSE
                var_code := 1;
            END IF;

            CLOSE a;
        END IF;

        CLOSE c;
        p_outnum1 := var_code;
    END;
END;
