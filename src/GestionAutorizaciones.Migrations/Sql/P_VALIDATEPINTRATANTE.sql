--------------------------------------------------------
--  DDL for Procedure P_VALIDATEPINTRATANTE
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_VALIDATEPINTRATANTE" (
    p_numsession IN NUMBER,
    p_instr1     IN VARCHAR2,
    p_outnum1    OUT NUMBER
) IS
BEGIN
    DECLARE
        fonos_row infox_session%rowtype;
        f_codigo  NUMBER(7);
      --
        CURSOR f IS
        SELECT
            codigo,
            'DR. '
            || medico.pri_nom
            || ' '
            || medico.pri_ape
        FROM
            medico medico
        WHERE
                medico.codigo = p_instr1
            AND trunc(sysdate) >= trunc(fec_ing)
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
        OPEN f;
        FETCH f INTO
            f_codigo,
            fonos_row.nom_afi;
        IF f%notfound THEN
            p_outnum1 := 1;
        ELSE
            p_outnum1 := 0;
            UPDATE infox_session
            SET
                med_tra = f_codigo
            WHERE
                numsession = p_numsession;

        END IF;

        CLOSE f;
    /**Exception
      when others then
        P_OUTNUM1 := 1;**/
    END;
END;
