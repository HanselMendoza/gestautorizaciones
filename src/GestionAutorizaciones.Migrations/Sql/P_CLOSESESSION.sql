--------------------------------------------------------
--  DDL for Procedure P_CLOSESESSION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_CLOSESESSION" (
    p_numsession IN NUMBER,
    p_outnum1    OUT NUMBER
) IS

    infox_session_row infox_session%rowtype;
    var_code          NUMBER(1) := 1;
    CURSOR c_session IS
    SELECT
        numsession,
        inicio
    FROM
        infox_session
    WHERE
        numsession = p_numsession
    FOR UPDATE;

BEGIN
    OPEN c_session;
    FETCH c_session INTO
        infox_session_row.numsession,
        infox_session_row.inicio;
    IF c_session%found THEN
        UPDATE infox_session
        SET
            termino = sysdate,
            duracion = to_number(to_char(sysdate, 'HHMISS')) - to_number(to_char(infox_session_row.inicio, 'HHMISS')),
            TIENE_EXCESOPORGRUPO = NULL
        WHERE
            CURRENT OF c_session;

        var_code := 0;
    END IF;

    CLOSE c_session;
    p_outnum1 := var_code;
END;
