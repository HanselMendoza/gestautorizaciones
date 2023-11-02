--------------------------------------------------------
--  DDL for Function F_BUSCA_COB_ESTUDIO_REPETICION
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "F_BUSCA_COB_ESTUDIO_REPETICION" (
    p_ase_uso   IN NUMBER,
    p_dep_uso   IN NUMBER,
    p_compania  IN NUMBER,
    p_ramo      IN NUMBER,
    p_sec_pol   IN NUMBER,
    p_servicio  IN NUMBER,
    p_tip_cob   IN NUMBER,
    p_cobertura IN NUMBER,
    p_origen    IN VARCHAR2
) RETURN VARCHAR2 IS

    var_dummy VARCHAR2(1);
    CURSOR c_ws IS
    SELECT
        'S'
    FROM
        coberturas_ws
    WHERE cobertura = p_cobertura
        AND nvl(estudio_repeticion, 'N') = 'S'
        AND origen = p_origen;

    CURSOR cob_c IS
    SELECT
        'S'
    FROM
        pre_c_cob01_v
    WHERE
            com_pol = p_compania
        AND ram_pol = p_ramo
        AND sec_pol = p_sec_pol
        AND per_hos = p_ase_uso
        AND nvl(dep_uso, 0) = nvl(p_dep_uso, 0)
        AND estatus = pkg_const.e_pre_convertida -- Convertida
        AND servicio = p_servicio
        AND tip_cob = p_tip_cob
        AND cobertura = p_cobertura;

BEGIN
    OPEN c_ws;
    FETCH c_ws INTO var_dummy;
    --
    IF c_ws%found THEN
        OPEN cob_c;
        FETCH cob_c INTO var_dummy;
        CLOSE cob_c;
    END IF;
    --
    CLOSE c_ws;
    RETURN var_dummy;
END;

/
