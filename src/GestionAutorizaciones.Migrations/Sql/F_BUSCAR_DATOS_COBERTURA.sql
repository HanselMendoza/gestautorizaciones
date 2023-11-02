--------------------------------------------------------
--  DDL for Function F_BUSCAR_DATOS_COBERTURA
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "F_BUSCAR_DATOS_COBERTURA" (
    p_fonos_row  IN infox_session%rowtype,
    var_tip_ser2 IN OUT infox_session.tip_ser%TYPE,
    var_tip_cob  IN OUT rec_c_sal.tip_cob%TYPE,
    var_dsp4     IN OUT ser_sal.descripcion%TYPE,
    var_dsp2     IN OUT tip_c_sal.descripcion%TYPE,
    var_dsp3     IN OUT cob_sal.descripcion%TYPE,
    no_m_lim_afi IN OUT no_m_cob.limite%TYPE,
    no_m_por_des IN OUT no_m_cob.por_des%TYPE
) RETURN NUMBER IS
    error CHAR(1) := NULL;
BEGIN
    IF p_fonos_row.tip_rec = 'ASEGURADO' THEN
        error := paq_matriz_validaciones.datos_cobertura_asegurados(p_fonos_row.tip_ser, p_fonos_row.cobertura, var_tip_ser2, var_tip_cob,
        var_dsp4,
                                                                   var_dsp2, var_dsp3);
    ELSIF p_fonos_row.tip_rec = 'NO_MEDICO' THEN
        error := paq_matriz_validaciones.datos_cobertura_no_medico(p_fonos_row.compania, p_fonos_row.ramo, p_fonos_row.secuencial, p_fonos_row.
        afiliado, p_fonos_row.tip_ser,
                                                                  p_fonos_row.plan, p_fonos_row.cobertura, var_tip_ser2, var_tip_cob,
                                                                  var_dsp4,
                                                                  var_dsp2, var_dsp3, no_m_lim_afi, no_m_por_des);
    ELSIF p_fonos_row.tip_rec = 'MEDICO' THEN
        error := paq_matriz_validaciones.datos_cobertura_medico(p_fonos_row.compania, p_fonos_row.ramo, p_fonos_row.secuencial, p_fonos_row.
        afiliado, p_fonos_row.tip_ser,
                                                               p_fonos_row.plan, p_fonos_row.cobertura, var_tip_ser2, var_tip_cob, var_dsp4,
                                                               var_dsp2, var_dsp3, no_m_lim_afi, no_m_por_des);
    END IF;

    RETURN ( error );
END;

/
