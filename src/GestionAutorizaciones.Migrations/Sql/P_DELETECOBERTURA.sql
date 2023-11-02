--------------------------------------------------------
--  DDL for Procedure P_DELETECOBERTURA
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_DELETECOBERTURA" (
    p_numsession IN NUMBER,
    p_innum1     IN NUMBER,
    p_outnum1    OUT NUMBER
) IS

    fecha_dia   DATE;
    var_code    NUMBER(2) := 99; -- Error desconocido (default)
    ano_rec     NUMBER(4);
    cia_rec     NUMBER(2);
    ram_rec     NUMBER(2);
    var_estatus NUMBER(3);
    cmb_estatus NUMBER(3) := 0;
    fonos_row   infox_session%rowtype;
    p_cobertura NUMBER(8) := p_innum1;
    CURSOR c_sesion IS
    SELECT
        ano_rec,
        sec_rec,
        compania,
        ramo
    FROM
        infox_session
    WHERE
        numsession = p_numsession;

    CURSOR c_rec IS
    SELECT
        estatus
    FROM
        reclamacion
    WHERE
            ano = fonos_row.ano_rec
        AND compania = fonos_row.compania
        AND ramo = fonos_row.ramo
        AND secuencial = fonos_row.sec_rec;

    CURSOR c_cob IS
    SELECT
        estatus
    FROM
        rec_c_sal
    WHERE
            ano = fonos_row.ano_rec
        AND compania = fonos_row.compania
        AND ramo = fonos_row.ramo
        AND secuencial = fonos_row.sec_rec
        AND cobertura = p_cobertura;

BEGIN

            -- Busca la sesión
    OPEN c_sesion;
    FETCH c_sesion INTO
        fonos_row.ano_rec,
        fonos_row.sec_rec,
        fonos_row.compania,
        fonos_row.ramo;

    IF c_sesion%found THEN
            -- Busca la reclamación
        OPEN c_rec;
        FETCH c_rec INTO var_estatus;
        IF
            c_rec%found
            AND ( var_estatus = pkg_const.e_reclamacion_vigente OR var_estatus = pkg_const.e_reclamacion_vigente2 )
        THEN
                -- Busca la cobertura
            OPEN c_cob;
            FETCH c_cob INTO var_estatus;
            IF
                c_cob%found
                AND ( var_estatus = pkg_const.e_reclamacion_vigente OR var_estatus = pkg_const.e_rec_c_sal_vigente )
            THEN
                    -- Cancela la cobertura

                DELETE FROM dbaper.reclamacion_cobertura_salud
                WHERE
                        ano = fonos_row.ano_rec
                    AND compania = fonos_row.compania
                    AND ramo = fonos_row.ramo
                    AND secuencial = fonos_row.sec_rec
                    AND cobertura = p_cobertura;

    --                    DBMS_OUTPUT.put_line('RowCount: ' || SQL%ROWCOUNT);

                var_code := 0; -- OK

            ELSE
                var_code := 3; -- Cobertura inválida

            END IF;

            CLOSE c_cob;
        ELSE
            var_code := 2; -- Reclamacion con estado invalido

        END IF;

        CLOSE c_rec;
    ELSE
        var_code := 1; -- No encontro la sesion

    END IF;

    CLOSE c_sesion;
    p_outnum1 := var_code;
    --      DBMS_OUTPUT.put_line('Resultado: ' || P_OUTNUM1);
END;
