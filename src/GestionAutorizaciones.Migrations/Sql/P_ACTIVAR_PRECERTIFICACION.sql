--------------------------------------------------------
--  DDL for Procedure P_ACTIVAR_PRECERTIFICACION
--------------------------------------------------------
  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_ACTIVAR_PRECERTIFICACION" (
    p_numsession IN NUMBER,
    p_instr1     IN VARCHAR2, -- NUM_PRECERTIF
    p_outstr1    OUT VARCHAR2,
    p_outstr2    OUT VARCHAR2,
    p_outnum1    OUT NUMBER
) IS

    fonos_row           infox_session%rowtype;
    precert_row         pre_cer%rowtype;
    var_code            VARCHAR2(2) := '01';
    pre_cob_row         pre_c_cob%rowtype;
    est_pre_certificada pre_cer.estatus%TYPE := 734; /* Almacena el Estatus Vigente de Pre-certificación. */
    vest_pre_convertida pre_cer.estatus%TYPE := 735;
    vfecha_dia          DATE;
    vtipo_precertif     VARCHAR2(1);
    vusuario            VARCHAR2(15);
    vcanal              reclamacion.canal%TYPE;
    CURSOR a IS
    SELECT
        tip_rec,
        afiliado,
        ano_rec,
        compania,
        ramo,
        reclamacion,
        sec_rec,
        plan,
        tip_ser,
        secuencial,
        to_number(asegurado)   asegurado,
        to_number(dependiente) dependiente,
        ase_carnet
    FROM
        infox_session
    WHERE
        numsession = p_numsession
    FOR UPDATE;

    CURSOR b IS
    SELECT
        a.ano,
        a.com_pol,
        a.ram_pol,
        a.secuencial,
        a.per_hos,
        a.dep_uso,
        a.fec_tra,
        a.pla_pol,
        a.servicio,
        a.estatus,
        a.sec_r_hos,
        a.sec_rec,
        nvl(a.chk_amb, 'N')
    FROM
        pre_certificacion a
    WHERE
            a.per_hos = fonos_row.asegurado
        AND nvl(a.dep_uso, 0) = nvl(fonos_row.dependiente, 0)
        AND a.tip_rec = fonos_row.tip_rec
        AND a.no_medico = fonos_row.afiliado
        AND a.secuencial = p_instr1
        AND a.estatus = (
            SELECT
                e.codigo
            FROM
                estatus e
            WHERE
                    e.codigo = a.estatus
                AND val_log = 'T'
        )
    FOR UPDATE SKIP LOCKED;

    CURSOR c IS
    SELECT
        SUM(nvl(mon_pag, 0))
    FROM
        pre_certificacion_cobertura
    WHERE
            ano = precert_row.ano
        AND com_pol = precert_row.com_pol
        AND ram_pol = precert_row.ram_pol
        AND secuencial = precert_row.secuencial;

    CURSOR d IS
    SELECT
        no_medico.tip_n_med,
        tip_n_med.descripcion
    FROM
        no_medico,
        tipo_no_medico tip_n_med
    WHERE
            no_medico.codigo = fonos_row.afiliado
        AND tip_n_med.codigo = no_medico.tip_n_med;

    tip_n_med_row       tipo_no_medico%rowtype;
    vsec_precertif      NUMBER;
    CURSOR p IS
    SELECT
        decode(vtipo_precertif, 'I', sec_r_hos, sec_rec)
    FROM
        pre_certificacion
    WHERE
            ano = precert_row.ano
        AND com_pol = precert_row.com_pol
        AND ram_pol = precert_row.ram_pol
        AND secuencial = precert_row.secuencial;

BEGIN
    vusuario := nvl(dbaper.f_busca_usu_registra_canales(user), 'FONOSALUD');
    vcanal := dbaper.pkg_pre_certificaciones.f_obten_canal_aut(vusuario);
    vfecha_dia := to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
    OPEN a;
    FETCH a INTO
        fonos_row.tip_rec,
        fonos_row.afiliado,
        fonos_row.ano_rec,
        fonos_row.compania,
        fonos_row.ramo,
        fonos_row.reclamacion,
        fonos_row.sec_rec,
        fonos_row.plan,
        fonos_row.tip_ser,
        fonos_row.secuencial,
        fonos_row.asegurado,
        fonos_row.dependiente,
        fonos_row.ase_carnet;

    IF a%found THEN
        OPEN b;
        FETCH b INTO
            precert_row.ano,
            precert_row.com_pol,
            precert_row.ram_pol,
            precert_row.secuencial,
            precert_row.per_hos,
            precert_row.dep_uso,
            precert_row.fec_tra,
            precert_row.pla_pol,
            precert_row.servicio,
            precert_row.estatus,
            precert_row.sec_r_hos,
            precert_row.sec_rec,
            precert_row.chk_amb;

        IF b%found THEN
            var_code := '00';
            OPEN c;
            FETCH c INTO pre_cob_row.mon_pag;
            CLOSE c;
          -- Para solo ejecutar proceso si esta en estatus vigente
            IF precert_row.estatus = est_pre_certificada THEN
            --
                vtipo_precertif := pkg_pre_certificaciones.f_obten_tipo_precertif(precert_row.servicio);
                IF vtipo_precertif = 'A' THEN
                    vtipo_precertif := 'R'; -- Reclamación
                END IF;
                IF precert_row.chk_amb = 'S' THEN
             --
                    vtipo_precertif := 'R'; -- Reclamación
             --

                END IF;

            -- Si la pre-certificación esta pendiente de confirmación no aplica este proceso
                IF
                    precert_row.sec_r_hos IS NULL
                    AND precert_row.sec_rec IS NULL
                THEN
              -- Proceso convertir pre-certificación en Ingreso ó Autorización
                    pkg_pre_certificaciones.p_autoriza_pre_certificacion(precert_row.ano, fonos_row.compania, fonos_row.ramo, precert_row.
                    secuencial, vfecha_dia,
                                                                        vtipo_precertif, vusuario, vcanal);
                END IF;

            -- Proceso confirmar pre-certificacion
                pkg_pre_certificaciones.p_confirmar_pre_certificacion(precert_row.ano, fonos_row.compania, fonos_row.ramo, precert_row.
                secuencial, vusuario,
                                                                     vcanal, 'P');

            -- Busca el secuencial de ingreso ó reclamacion
                OPEN p;
                FETCH p INTO vsec_precertif;
                CLOSE p;
            END IF;
          --
            UPDATE infox_session
            SET
                ano_rec = precert_row.ano,
                compania = precert_row.com_pol,
                ramo = precert_row.ram_pol,
                sec_rec = precert_row.secuencial,
                reclamacion = precert_row.secuencial,
                asegurado = precert_row.per_hos,
                dependiente = precert_row.dep_uso,
                mon_rec = pre_cob_row.mon_pag,
                fec_ape = precert_row.fec_tra,
                plan = precert_row.pla_pol,
                tip_ser = precert_row.servicio
            WHERE
                numsession = p_numsession;
          --
        END IF;

        CLOSE b;
    END IF;

    CLOSE a;
    UPDATE infox_session
    SET
        code = var_code,
        usuario = upper(vusuario),
        termino = sysdate,
        duracion = to_number(to_char(sysdate, 'HHMISS')) - to_number(to_char(inicio, 'HHMISS'))
    WHERE
        numsession = p_numsession;

    p_outnum1 := var_code;
    p_outstr1 := vsec_precertif;
    p_outstr2 := vtipo_precertif;
    COMMIT;
END;
