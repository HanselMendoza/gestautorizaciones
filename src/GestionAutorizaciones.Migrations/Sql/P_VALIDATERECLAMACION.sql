--------------------------------------------------------
--  DDL for Procedure P_VALIDATERECLAMACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_VALIDATERECLAMACION" (
    p_numsession IN NUMBER,
    p_instr1     IN VARCHAR2,
    p_outnum1    OUT NUMBER
) IS
-- procedure valida que la reclamacion exista Y que sea del afiliado --
-- 0-> valido 1-> invalido --

    /* @% Buscar Reclamacion */ 
    /* Descripcion : Busca datos de una reclamacion */
    rec_row     reclamacion%rowtype;
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
        to_number(substr(p_instr1, 1, 15)) sec_rec,
        tip_rec,
        afiliado,
        secuencial,
        reclamacion,
        to_number(asegurado)               asegurado,
        to_number(dependiente)             dependiente
    FROM
        infox_session
    WHERE
        numsession = p_numsession
    FOR UPDATE;

    CURSOR b IS
    SELECT
        a.ano,
        a.compania,
        a.ramo,
        a.secuencial,
        a.ase_uso,
        a.dep_uso,
        a.fec_tra
    FROM
        reclamacion a
    WHERE
            a.ase_uso = fonos_row.asegurado
        AND ( a.dep_uso = nvl(fonos_row.dependiente, 0)
              OR a.dep_uso IS NULL
              AND nvl(fonos_row.dependiente, 0) = 0 )
        AND a.ano = ano_rec
        AND a.compania = fonos_row.compania
        AND a.ramo = fonos_row.ramo
        AND a.secuencial = fonos_row.sec_rec
        AND a.tip_rec = fonos_row.tip_rec
        AND a.reclamante = fonos_row.afiliado
        AND a.estatus = (
            SELECT
                e.codigo
            FROM
                estatus e
            WHERE
                    e.codigo = a.estatus
                AND val_log = pkg_const.c_true
        );

    CURSOR c IS
    SELECT
        SUM(nvl(mon_pag, 0))
    FROM
        rec_c_sal
    WHERE
            ano = rec_row.ano
        AND compania = rec_row.compania
        AND ramo = rec_row.ramo
        AND secuencial = rec_row.secuencial;

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
        fonos_row.reclamacion,
        fonos_row.asegurado,
        fonos_row.dependiente;

    IF a%found THEN
        OPEN b;
        FETCH b INTO
            rec_row.ano,
            rec_row.compania,
            rec_row.ramo,
            rec_row.secuencial,
            rec_row.ase_uso,
            rec_row.dep_uso,
            rec_row.fec_tra;

        IF b%found THEN
            fonos_row.asegurado := rec_row.ase_uso;
            fonos_row.dependiente := rec_row.dep_uso;
            OPEN c;
            FETCH c INTO rec_cob_row.mon_pag;
            IF c%found THEN
                UPDATE infox_session
                SET
                    code = 0,
                    ano_rec = rec_row.ano,
                    compania = rec_row.compania,
                    ramo = rec_row.ramo,
                    sec_rec = rec_row.secuencial,
                    secuencial = fonos_row.secuencial,
                    asegurado = fonos_row.asegurado,
                    dependiente = fonos_row.dependiente,
                    mon_rec = rec_cob_row.mon_pag,
                    fec_ape = rec_row.fec_tra,
                    reclamacion = fonos_row.reclamacion
                WHERE
                    CURRENT OF a;

                var_code := 0;
            END IF;

            CLOSE c;
        ELSE
            UPDATE infox_session
            SET
                code = 1
            WHERE
                CURRENT OF a;

            var_code := 1;
        END IF;

    END IF;

    CLOSE a;
    CLOSE b;
    p_outnum1 := var_code;
END;
