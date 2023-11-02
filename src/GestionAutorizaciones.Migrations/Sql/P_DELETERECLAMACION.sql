--------------------------------------------------------
--  DDL for Procedure P_DELETERECLAMACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_DELETERECLAMACION" (
    p_numsession IN NUMBER,
    p_instr1     IN VARCHAR2,
    p_innum1     IN NUMBER,
    p_innum2     IN NUMBER,
    p_outnum1    OUT NUMBER
) IS
-- procedure borra una reclamacion del afiliado y que no haya sifo procesada aun. --
-- 0->ok 1-> error 2-> que ya no se puede borrar, ha sido procesada--

    /* Descripcion : Cancela una Reclamacion cambiando su estatus en la tabla RECLAMACION */
    fecha_dia   DATE;
    var_code    NUMBER(2) := 1;
    ano_rec     NUMBER(4);
    cia_rec     NUMBER(2);
    ram_rec     NUMBER(2);
    var_estatus NUMBER(3);
    cmb_estatus NUMBER(3) := 0;
    fonos_row   infox_session%rowtype;
    CURSOR a IS
    SELECT
        sec_rec,
        afiliado,
        tip_rec,
        compania,
        ramo
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
        AND reclamante = fonos_row.afiliado
    FOR UPDATE;

    vusuario    VARCHAR2(15);
BEGIN
    vusuario := nvl(dbaper.f_busca_usu_registra_canales(user), 'FONOSALUD');
    fecha_dia := to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
    cmb_estatus := nvl(p_innum1, 0);
    IF ( cmb_estatus <= 0 ) THEN
        cmb_estatus := 52;
    END IF;
    OPEN a;
    FETCH a INTO
        fonos_row.sec_rec,
        fonos_row.afiliado,
        fonos_row.tip_rec,
        cia_rec,
        ram_rec;

    IF a%found THEN
        ano_rec := to_number(substr(to_char(fecha_dia, 'DD/MM/YYYY'), 7, 4));

        OPEN b;
        FETCH b INTO var_estatus;
        IF
            b%found
            AND ( var_estatus = 83 OR var_estatus = 52 )
        THEN
            UPDATE reclamacion
            SET
                estatus = cmb_estatus,
                motivo_estatus = p_innum2
            WHERE
                CURRENT OF b;

            var_code := 0;
            UPDATE rec_c_sal
            SET
                estatus = 57
            WHERE
                    ano = ano_rec
                AND compania = cia_rec
                AND ramo = ram_rec
                AND secuencial = fonos_row.sec_rec;

               /*Insert para registrar el comentario de cancelacion Miguel A. Carrion 19/03/2021*/
            INSERT INTO coment_reclamaciones (
                ano,
                compania,
                ramo,
                secuencial,
                usuario,
                fecha,
                coment,
                fecha_creo
            ) VALUES (
                ano_rec,
                cia_rec,
                ram_rec,
                fonos_row.sec_rec,
                vusuario,
                fecha_dia,
                p_instr1,
                fecha_dia
            );

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
END;
