--------------------------------------------------------
--  DDL for Procedure P_VALIDATEPIN
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_VALIDATEPIN" (
    p_numsession IN NUMBER,
    p_instr1     IN VARCHAR2,
    p_instr2     IN VARCHAR2,
    p_outnum1    OUT NUMBER
) IS
    fecha_dia   DATE; /* Variable que almacena la Fecha del Dia. */
      --DUMMY     VARCHAR2(1);
    fonos_row   infox_session%rowtype;
      --CONT      NUMBER(2);
    var_code    NUMBER(1) := 1;
      --
    var_cod_err NUMBER := NULL;  --Varible para manejar el codigo de error que se interpretara en la emergencia por el monto Miguel A. Carrion FCCM 15/10/2021
      --
    CURSOR b IS
    SELECT
        tip_afi,
        '' cat_n_med
    FROM
        fonos_pin_afiliado
    WHERE
            afiliado = p_instr1
        AND pin = p_instr2;

    CURSOR e IS
    SELECT
        substr(no_medico.nombre, 1, 59)
    FROM
        no_medico no_medico
    WHERE
            no_medico.codigo = p_instr1
        AND fecha_dia >= trunc(fec_ing)
        AND no_medico.estatus = (
            SELECT
                codigo
            FROM
                estatus
            WHERE
                    codigo = no_medico.estatus
                AND val_log = pkg_const.C_TRUE
        );

    CURSOR f IS
    SELECT
        'DR. '
        || medico.pri_nom
        || ' '
        || medico.pri_ape
    FROM
        medico medico
    WHERE
            medico.codigo = p_instr1
        AND fecha_dia >= trunc(fec_ing)
        AND medico.estatus = (
            SELECT
                codigo
            FROM
                estatus
            WHERE
                    codigo = medico.estatus
                AND val_log = pkg_const.C_TRUE
        );

BEGIN
    fecha_dia := to_date(to_char(sysdate, 'dd/mm/yyyy'), 'dd/mm/yyyy');
    OPEN b;
    FETCH b INTO
        fonos_row.tip_rec,
        fonos_row.cat_n_med;
    IF b%found THEN
        IF fonos_row.tip_rec = 'MEDICO' THEN
            OPEN f;
            FETCH f INTO fonos_row.nom_afi;
            IF f%notfound THEN
                var_code := 1;
            ELSE
                var_code := 0;
            END IF;

            CLOSE f;
        ELSE
            OPEN e;
            FETCH e INTO fonos_row.nom_afi;
            IF e%notfound THEN
                var_code := 1;
            ELSE
                var_code := 0;
            END IF;

            CLOSE e;
        END IF;
    ELSE
        var_code := 2;
    END IF;

    CLOSE b;
    p_outnum1 := var_code;
    UPDATE infox_session
    SET
        tip_rec = fonos_row.tip_rec,
        nom_afi = fonos_row.nom_afi,
        cat_n_med = fonos_row.cat_n_med,
        afiliado = substr(p_instr1, 1, 16),
        pin = substr(p_instr2, 1, 10)
    WHERE
        numsession = p_numsession;
    /*EXCEPTION
      WHEN OTHERS THEN
        VAR_CODE  := 1;
        P_OUTNUM1 := VAR_CODE;*/
END;
