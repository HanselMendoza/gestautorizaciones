--------------------------------------------------------
--  DDL for Procedure P_OPENRECLAMACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OPENRECLAMACION" (
    p_numsession IN NUMBER,
    p_innum1     IN NUMBER,
    p_outstr1    OUT VARCHAR2,
    p_outstr2    OUT VARCHAR2,
    p_outnum1    OUT NUMBER
) IS
  
    /* @% Agregar Reclamacion */
    /* Nombre de la Funcion :  Agregar Reclamacion   */
    /* Descripcion : Graba en la tabla RECLAMACION  un registro con un numero de  */
    /* reclamacion   */

    fecha_dia       DATE;
    var_code        NUMBER(2) := 1;
    sec_reclamacion NUMBER(9);
    var_ano_rec     VARCHAR2(4);
    var_reclamante  NUMBER(14);
    var_asegurado   VARCHAR2(15);
    var_dependiente VARCHAR2(3);
    var_compania    NUMBER(2);
    var_ramo        NUMBER(2);
    var_secuencial  NUMBER(7);
    var_plan        NUMBER(3);
    var_tip_rec     VARCHAR2(10);
    var_tip_ser     NUMBER(2);
    var_tip_a_uso   VARCHAR2(10);
    var_ase_uso     NUMBER(11);
    var_dep_uso     NUMBER(3);
    var_med_tra     NUMBER(7);
    var_rie_lab     VARCHAR2(1);
    var_num_pla     VARCHAR2(20);
    var_tip_cob     NUMBER(3); -- MIREX
    vusuario        VARCHAR2(15);
    vcanal          reclamacion.canal%TYPE;
    CURSOR i (
        ccdramo NUMBER
    ) IS
    SELECT
        'L'   loc_pro,
        'P'   tip_pro,
        '001' cdmoneda
    FROM
        ramo
    WHERE
            codigo = ccdramo
        AND tip_ram = 4; -- Salud Internacional
      --
    i_row           i%rowtype;
      --
    CURSOR b IS
    SELECT
        to_char(sysdate, 'YYYY')
    FROM
        sys.dual;

    CURSOR c IS
    SELECT
        afiliado,
        asegurado,
        dependiente,
        compania,
        ramo,
        secuencial,
        plan,
        tip_rec,
        tip_ser,
        med_tra,
        rie_lab,
        ase_carnet, -- Indica el Numero de Plastico digitado. GMa�on 15/09/2010
        tip_cob -- MIREX
    FROM
        infox_session
    WHERE
        numsession = p_numsession
    FOR UPDATE;

BEGIN
    vusuario := nvl(dbaper.f_busca_usu_registra_canales(user), 'FONOSALUD');
    vcanal := dbaper.pkg_pre_certificaciones.f_obten_canal_aut(vusuario);
    fecha_dia := to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
    OPEN b;
    FETCH b INTO var_ano_rec;
    CLOSE b;
      --
    OPEN c;
    FETCH c INTO
        var_reclamante,
        var_asegurado,
        var_dependiente,
        var_compania,
        var_ramo,
        var_secuencial,
        var_plan,
        var_tip_rec,
        var_tip_ser,
        var_med_tra,
        var_rie_lab,
        var_num_pla,
        var_tip_cob; --MIREX
    IF c%found THEN
        sec_reclamacion := fnc_adm_contador('RECLAMACION', var_ano_rec, var_compania, var_ramo);
        --
        var_ase_uso := to_number(var_asegurado);
        var_dep_uso := to_number(var_dependiente);
        --
        IF nvl(var_dep_uso, 0) > 0 THEN
            var_tip_a_uso := 'DEPENDIENT';
        ELSE
            var_tip_a_uso := 'ASEGURADO';
            var_dep_uso := NULL;
            IF pkg_saludint.f_ramo_salud_int(var_ramo) THEN
            -- Incluir 0 para asegurados y poder relacionar con la vista ASE_DEP01_V [Enfoco | GM]
                var_dep_uso := 0;
            END IF;
        END IF;
        --
        OPEN i(var_ramo);
        FETCH i INTO
            i_row.loc_pro,
            i_row.tip_pro,
            i_row.cdmoneda;
        CLOSE i;
        INSERT INTO reclamacion (
            ano,
            compania,
            ramo,
            secuencial,
            sec_pol,
            plan,
            usu_ing,
            fec_ape,
            fec_tra,
            fec_ser,
            tip_rec,
            reclamante,
            tip_a_uso,
            ase_uso,
            tip_ser,
            estatus,
            dep_uso,
            referencia,
            rie_lab,
            num_pla,
            canal,
            loc_pro,
            tip_pro,
            cdmoneda
        ) VALUES (
            var_ano_rec,
            var_compania,
            var_ramo,
            sec_reclamacion,
            var_secuencial,
            var_plan,
            vusuario,
            sysdate, -- FECHA_DIA, Trunc (No tenia la Hora) VA
            sysdate,
            fecha_dia,
            var_tip_rec,
            var_reclamante,
            var_tip_a_uso,
            var_ase_uso,
            var_tip_ser,
            dbaper.f_busca_usu_est_inic_canales(user), --Se agrego funcion para obtener los estatus iniciar   del reclamos
                                                         --- JOSE DE LEON @ENFOCO
           --DECODE(vUsuario, 'KIOSKO', 179, 83), -- AGREGADO POR LEONARDO PROYECTO KIOSKO
            var_dep_uso,
            var_med_tra,
            var_rie_lab,
            var_num_pla,
            vcanal,
            i_row.loc_pro,
            i_row.tip_pro,
            i_row.cdmoneda
        );

        /*----------------------------------------------------------------------
        --  Victor Acevedo
        --  Proyecto Prescriptor 01-Ago-2016
        --  Insertando en la tabla de prescriptores
        */ ----------------------------------------------------------------------
        IF nvl(p_innum1, 0) > 0 THEN
            INSERT INTO reclamacion_prescriptor (
                ano,
                compania,
                ramo,
                secuencial,
                cod_medico,
                creado_por,
                creado_en
            ) VALUES (
                var_ano_rec,
                var_compania,
                var_ramo,
                sec_reclamacion,
                p_innum1,
                vusuario,
                sysdate
            );

        END IF;

        var_code := 0;
        UPDATE infox_session
        SET
            code = var_code,
            ano_rec = var_ano_rec,
            sec_rec = sec_reclamacion,
            reclamacion = ltrim(to_char(sec_reclamacion))
        WHERE
            CURRENT OF c;

    END IF;

    CLOSE c;
    p_outnum1 := var_code;
    p_outstr1 := sec_reclamacion;
    p_outstr2 := var_ramo;
END;
