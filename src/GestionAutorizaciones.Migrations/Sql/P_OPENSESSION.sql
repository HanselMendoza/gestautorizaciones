--------------------------------------------------------
--  DDL for Procedure P_OPENSESSION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OPENSESSION" (
    p_instr1  IN VARCHAR2,
    p_outnum1 OUT NUMBER,
    p_outnum2 OUT NUMBER
) IS

    infox_session_row infox_session%rowtype;
    var_code          NUMBER(1) := 1;
    var_maquina       VARCHAR2(30);
      --
    CURSOR c_seqsession IS
    SELECT
        seqsession.NEXTVAL
    FROM
        sys.dual;
      --
    CURSOR c_maquina IS
    SELECT
        substr(machine, 1, 30)
    FROM
        v$session
    WHERE
            username = user
        AND audsid = sys_context('USERENV', 'SESSIONID');

BEGIN
    OPEN c_seqsession;
    FETCH c_seqsession INTO infox_session_row.numsession;
    IF c_seqsession%found THEN
        OPEN c_maquina;
        FETCH c_maquina INTO var_maquina;
        CLOSE c_maquina;
        INSERT INTO infox_session (
            numsession,
            inicio,
            maquina
        ) VALUES (
            infox_session_row.numsession,
            sysdate,
            var_maquina
        );

        var_code := 0;
    END IF;

    CLOSE c_seqsession;
    p_outnum1 := var_code;
    p_outnum2 := infox_session_row.numsession;
END;
