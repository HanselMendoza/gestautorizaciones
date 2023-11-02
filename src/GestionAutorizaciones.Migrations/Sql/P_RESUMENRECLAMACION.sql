--------------------------------------------------------
--  DDL for Procedure P_RESUMENRECLAMACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_RESUMENRECLAMACION" (
    p_numsession IN NUMBER,
    p_outstr1    OUT VARCHAR2,
    p_outnum1    OUT NUMBER
) IS
-- procedure Resumen de reclamaciones diarias aperturadas por fonosalud --
-- 0-> valido 1-> invalido/no hay reclamos para este dia --
    /* @% Buscar Reclamacion */
    /* Descripcion : Busca datos de una reclamacion */
    fonos_row   infox_session%rowtype;
    rec_cob_row rec_c_sal%rowtype;
    var_code    NUMBER(1) := 1;
    fecha_dia   DATE;
    ano_rec     NUMBER(4);
    CURSOR a IS
    SELECT
        ano_rec,
        compania,
        ramo,
        sec_rec,
        tip_rec,
        afiliado,
        secuencial,
        reclamacion
    FROM
        infox_session
    WHERE
        numsession = p_numsession
    FOR UPDATE;

    CURSOR b IS
    SELECT
        SUM(b.mon_pag)
    FROM
        reclamacion a,
        rec_c_sal   b
    WHERE
            a.ano = ano_rec
        AND a.compania = fonos_row.compania
        AND a.ramo = fonos_row.ramo
        AND a.secuencial = fonos_row.sec_rec
        AND a.tip_rec = fonos_row.tip_rec
        AND a.reclamante = fonos_row.afiliado
        AND trunc(a.fec_ape) = trunc(fecha_dia)
        AND a.estatus = (
            SELECT
                e.codigo
            FROM
                estatus e
            WHERE
                    e.codigo = a.estatus
                AND val_log = pkg_const.c_true
        )
        AND b.ano = a.ano
        AND b.compania = a.compania
        AND b.ramo = a.ramo
        AND b.secuencial = a.secuencial;

BEGIN
    fecha_dia := to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
    ano_rec := to_number(substr(to_char(fecha_dia, 'DD/MM/YYYY'), 7, 4));

    OPEN a;
    FETCH a INTO
        fonos_row.ano_rec,
        fonos_row.compania,
        fonos_row.ramo,
        fonos_row.sec_rec,
        fonos_row.tip_rec,
        fonos_row.afiliado,
        fonos_row.secuencial,
        fonos_row.reclamacion;

    IF a%found THEN
        OPEN b;
        FETCH b INTO rec_cob_row.mon_pag;
        IF
            b%found
            AND nvl(rec_cob_row.mon_pag, 0) > 0
        THEN
            UPDATE infox_session
            SET
                code = 0
            WHERE
                CURRENT OF a;

            var_code := 0;
        ELSE
            UPDATE infox_session
            SET
                code = 1
            WHERE
                CURRENT OF a;

            var_code := 1;
        END IF;

        CLOSE b;
    ELSE
        var_code := 2;
    END IF;

    CLOSE a;
    p_outstr1 := ltrim(to_char(rec_cob_row.mon_pag, '999999990.00'));
    p_outnum1 := var_code;
END;
