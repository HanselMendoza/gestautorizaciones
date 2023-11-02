--------------------------------------------------------
--  DDL for Function F_BUSCA_ORIGEN_COB_MON_MAX
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "F_BUSCA_ORIGEN_COB_MON_MAX" (
    p_servicio  IN NUMBER,
    p_tip_cob   IN NUMBER,
    p_cobertura IN NUMBER,
    p_origen    IN VARCHAR2
) RETURN NUMBER IS

    v_monto_maximo NUMBER(11, 2);
    CURSOR c_ws IS
    SELECT
        nvl(mon_max, 0)
    FROM
        coberturas_ws
    WHERE
            servicio = p_servicio
        AND tip_cob = p_tip_cob
        AND cobertura = p_cobertura
        AND origen = p_origen;

BEGIN
    OPEN c_ws;
    FETCH c_ws INTO v_monto_maximo;
    CLOSE c_ws;
    RETURN v_monto_maximo;
END;

/
