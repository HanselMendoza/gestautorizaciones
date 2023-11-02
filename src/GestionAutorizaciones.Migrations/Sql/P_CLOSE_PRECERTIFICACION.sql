--------------------------------------------------------
--  DDL for Procedure P_CLOSE_PRECERTIFICACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_CLOSE_PRECERTIFICACION" (
    p_numsession IN NUMBER,
    p_outstr1    OUT VARCHAR2,
    p_outstr2    OUT VARCHAR2,
    p_outnum1    OUT NUMBER
) IS
    /* Descripcion : Realmente no cambia ningun estatus, la reclamacion ya fue creada con estatus definitivo.*/
    /*               Retorno el total general a pagar por ars y por el asegurado*/
    fecha_dia       DATE;
    var_code        NUMBER(2) := 1;
    ano_rec         NUMBER(4);
    var_mon_pag     NUMBER(16, 2);
    var_mon_ded     NUMBER(16, 2);
    fonos_row       infox_session%rowtype;
    v_error_message VARCHAR2(2000);
    precert_row     pre_cer%rowtype;
    vtipo_precertif VARCHAR2(1);
    CURSOR a IS
    SELECT
        ano_rec,
        sec_rec,
        afiliado,
        tip_rec,
        compania,
        ramo,
        tot_mon_ded
    FROM
        infox_session
    WHERE
        numsession = p_numsession
    FOR UPDATE;

    CURSOR b IS
    SELECT
        estatus,
        sec_r_hos,
        sec_rec,
        servicio
    FROM
        pre_certificacion
    WHERE
            ano = fonos_row.ano_rec
        AND com_pol = fonos_row.compania
        AND ram_pol = fonos_row.ramo
        AND secuencial = fonos_row.sec_rec
        AND tip_rec = fonos_row.tip_rec
        AND no_medico = fonos_row.afiliado;

    CURSOR c IS
    SELECT
        SUM(nvl(mon_pag, 0))
    FROM
        pre_c_cob
    WHERE
            ano = fonos_row.ano_rec
        AND com_pol = fonos_row.compania
        AND ram_pol = fonos_row.ramo
        AND secuencial = fonos_row.sec_rec;

BEGIN
    fecha_dia := to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
    OPEN a;
    FETCH a INTO
        fonos_row.ano_rec,
        fonos_row.sec_rec,
        fonos_row.afiliado,
        fonos_row.tip_rec,
        fonos_row.compania,
        fonos_row.ramo,
        var_mon_ded;

    IF a%found THEN
        ano_rec := to_number(substr(to_char(fecha_dia, 'DD/MM/YYYY'), 7, 4));

        OPEN b;
        FETCH b INTO
            precert_row.estatus,
            precert_row.sec_r_hos,
            precert_row.sec_rec,
            precert_row.servicio;

        IF
            b%found
            AND precert_row.estatus IN ( 734 )
        THEN
            OPEN c;
            FETCH c INTO var_mon_pag;
            CLOSE c;
            var_code := 0;
        ELSE
            var_code := 1;
        END IF;

        CLOSE b;
        --
        UPDATE infox_session
        SET
            code = var_code
        WHERE
            CURRENT OF a;

    END IF;

    CLOSE a;
    p_outnum1 := var_code;
    p_outstr1 := ltrim(to_char(nvl(var_mon_pag, 0), '999999990.00'));
    p_outstr2 := ltrim(to_char(nvl(var_mon_ded, 0), '999999990.00'));
      --
END;
