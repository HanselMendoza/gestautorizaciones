--------------------------------------------------------
--  DDL for Procedure INFOXPROC
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "INFOXPROC" (
    p_name       IN VARCHAR2,
    p_numsession IN NUMBER,
    p_instr1     IN VARCHAR2,
    p_instr2     IN VARCHAR2,
    p_innum1     IN NUMBER,
    p_innum2     IN NUMBER,
    p_outstr1    OUT VARCHAR2,
    p_outstr2    OUT VARCHAR2,
    p_outnum1    OUT NUMBER,
    p_outnum2    OUT NUMBER
) IS
    vusuario VARCHAR2(15) := nvl(dbaper.f_busca_usu_registra_canales(user), 'FONOSALUD');
BEGIN
    IF upper(p_name) = 'GETPIN' THEN
        SELECT
            pin
        INTO p_outnum1
        FROM
            fonos_pin_afiliado
        WHERE
                tip_afi = 'MEDICO'
            AND afiliado = p_instr1;

    ELSIF upper(p_name) = 'RIESGOSLABORALES' THEN
        UPDATE infox_session
        SET
            rie_lab = pkg_const.c_si
        WHERE
            numsession = p_numsession;

    ELSIF upper(p_name) = 'VALIDATEPINTRATANTE' THEN
        p_validatepintratante(p_numsession, p_instr1, p_outnum1);
    ELSIF upper(p_name) = 'VALIDATEPIN' THEN
        p_validatepin(p_numsession, p_instr1, p_instr2, p_outnum1);
    ELSIF upper(p_name) = 'VALIDATEASEGURADO' THEN
        p_validateasegurado(p_numsession, p_instr1, p_outnum1, p_outnum2);
    ELSIF upper(p_name) = 'VALIDATERECLAMACION' THEN
        p_validatereclamacion(p_numsession, p_instr1, p_outnum1);
    ELSIF upper(p_name) = 'VALIDATECOBERTURA' THEN
        p_validatecobertura(p_numsession, p_instr1, p_instr2, p_innum1, p_innum2,
                           p_outstr1, p_outstr2, p_outnum1, p_outnum2);
    ELSIF upper(p_name) = 'INSERTCOBERTURA' THEN
        IF vusuario = 'KIOSKO' THEN
            p_insertcobertura_precertif(p_numsession, p_outnum1);
        ELSE
            p_insertcobertura(p_numsession, p_innum1, p_outnum1);
        END IF;
    ELSIF upper(p_name) = 'OPENSESSION' THEN
        p_opensession(p_instr1, p_outnum1, p_outnum2);
    ELSIF upper(p_name) = 'CLOSESESSION' THEN
        p_closesession(p_numsession, p_outnum1);
    ELSIF upper(p_name) = 'OPENRECLAMACION' THEN
        IF vusuario = 'KIOSKO' THEN
            p_open_precertif(p_numsession, p_outstr1, p_outstr2, p_outnum1);
        ELSE
            p_openreclamacion(p_numsession, p_innum1, p_outstr1, p_outstr2, p_outnum1);
        END IF;
    ELSIF upper(p_name) = 'CLOSERECLAMACION' THEN
        IF vusuario = 'KIOSKO' THEN
            p_close_precertificacion(p_numsession, p_outstr1, p_outstr2, p_outnum1);
        ELSE
            p_closereclamacion(p_numsession, p_outstr1, p_outstr2, p_outnum1);
        END IF;
    ELSIF upper(p_name) = 'DELETECOBERTURA' THEN
        p_deletecobertura(p_numsession, p_innum1, p_outnum1);
    ELSIF upper(p_name) = 'DELETERECLAMACION' THEN
        p_deletereclamacion(p_numsession, p_instr1, p_innum1, p_innum2, p_outnum1);
    ELSIF upper(p_name) = 'RESUMENDIA' THEN
        p_resumenreclamacion(p_numsession, p_outstr1, p_outnum1);
    END IF;
END;
  -- ******************************************************************** --
