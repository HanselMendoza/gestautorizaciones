--------------------------------------------------------
--  DDL for Procedure P_CLOSERECLAMACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_CLOSERECLAMACION" (
    p_numsession IN NUMBER,
    p_outstr1    OUT VARCHAR2,
    p_outstr2    OUT VARCHAR2,
    p_outnum1    OUT NUMBER
) IS 
-- procedure hace que la reclamacion recien aperturada sea definitiva --
  -- 0->ok 1-> error --
    /* Descripcion : Realmente no cambia ningun estatus, la reclamacion ya fue creada con estatus definitivo.*/
    /*               Retorno el total general a pagar por ars y por el asegurado*/
    fecha_dia       DATE;
    var_code        NUMBER(2) := 1;
    ano_rec         NUMBER(4);
    cia_rec         NUMBER(2);
    ram_rec         NUMBER(2);
    var_estatus     NUMBER(3);
    var_mon_pag     NUMBER(16, 2);
    var_mon_ded     NUMBER(16, 2);
    fonos_row       infox_session%rowtype;
    v_error_message VARCHAR2(2000);
    CURSOR a IS
    SELECT
        sec_rec,
        afiliado,
        tip_rec,
        compania,
        ramo,
        tot_mon_ded
    FROM
        infox_session
    WHERE
        numsession = p_numsession
    FOR UPDATE;

    CURSOR b IS
    SELECT
        estatus
    FROM
        reclamacion
    WHERE
            ano = ano_rec
        AND compania = cia_rec
        AND ramo = ram_rec
        AND secuencial = fonos_row.sec_rec
        AND tip_rec = fonos_row.tip_rec
        AND reclamante = fonos_row.afiliado;

    CURSOR c IS
    SELECT
        SUM(nvl(mon_pag, 0)) --, SUM(NVL(MON_DED,0))
    FROM
        rec_c_sal
    WHERE
            ano = ano_rec
        AND compania = cia_rec
        AND ramo = ram_rec
        AND secuencial = fonos_row.sec_rec;

BEGIN
    fecha_dia := to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
    OPEN a;
    FETCH a INTO
        fonos_row.sec_rec,
        fonos_row.afiliado,
        fonos_row.tip_rec,
        cia_rec,
        ram_rec,
        var_mon_ded;

    IF a%found THEN
        ano_rec := to_number(substr(to_char(fecha_dia, 'DD/MM/YYYY'), 7, 4));

        UPDATE reclamacion
        SET
            estatus = f_obten_parametro_seus('ESTATUS_FONO_WEB', cia_rec)
        WHERE
                ano = ano_rec
            AND compania = cia_rec
            AND ramo = ram_rec
            AND secuencial = fonos_row.sec_rec
            AND tip_rec = fonos_row.tip_rec
            AND reclamante = fonos_row.afiliado
            AND estatus = f_obten_parametro_seus('ESTATUS_TRANSITORIO', cia_rec); --- EN EL CIERRE DE LA SESSION  BUSCAMOS EL RECLAMOS  PARA COLOCAR EL ESTATUS QUE LE CORRESPONDE AL IVR
                              ---Jose De Leon @Enfoco




        OPEN b;
        FETCH b INTO var_estatus;
        IF
            b%found
            AND var_estatus IN ( 83, 179, 122 ) -- KIOSKO
        THEN
            OPEN c;
            FETCH c INTO var_mon_pag; /*--, VAR_MON_DED;*/
            CLOSE c;
            var_code := 0;
        ELSE
            var_code := 1;
        END IF;

        UPDATE infox_session
        SET
            code = var_code
        WHERE
            CURRENT OF a;

    END IF;

    CLOSE a;
    CLOSE b;
    p_outnum1 := var_code;
    p_outstr1 := ltrim(to_char(nvl(var_mon_pag, 0), '999999990.00'));
    p_outstr2 := ltrim(to_char(nvl(var_mon_ded, 0), '999999990.00'));

      -- PASA LAS RECLAMACIONES PARA SALUD CORE.
    IF ram_rec = 93 THEN
        NULL;/*DBAPER.PAQ_SYNC_RECLAMACION.P_SYNC_REC_INF_SAL(ANO_REC,
                                                       CIA_REC,
                                                       RAM_REC,
                                                       FONOS_ROW.SEC_REC,
                                                       'INSERT',
                                                       V_ERROR_MESSAGE);*/
    END IF;

      -- Proceso para crear un Ingreso a partir de una Reclamacion dada
    BEGIN
        p_ingreso_from_reclamac(p_numsession);
    END;
END;
