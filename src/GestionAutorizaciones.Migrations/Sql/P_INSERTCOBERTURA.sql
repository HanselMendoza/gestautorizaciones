--------------------------------------------------------
--  DDL for Procedure P_INSERTCOBERTURA
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_INSERTCOBERTURA" (
    p_numsession IN NUMBER,
    p_innum1     IN NUMBER,
    p_outnum1    OUT NUMBER
) IS

    /* @%  Agregar Cobertura a Reclamacion */
    /* Nombre de la Funcion :  Agregar Cobertura a Reclamacion   */
    /* Descripcion : Graba en la tabla REC_C_SAL  un registro con un numero de    */
    /*               reclamacion */
    fonos_row      infox_session%rowtype;
    fecha_dia      DATE;
    var_code       NUMBER(2) := 1;
    var_reclamante NUMBER(14);
    var_tip_rec    VARCHAR2(10);
    var_tip_ser    NUMBER(2);
    var_tip_cob    NUMBER(3);
    var_cobertura  NUMBER(5);
    var_mon_rec    NUMBER(11, 2);
    var_fec_ser    DATE;
    var_estatus    NUMBER(3);
    var_secuencia  NUMBER(7);
    var_mon_pag    NUMBER(11, 2);
    var_mon_ded    NUMBER(11, 2);
    var_por_coa    NUMBER(11, 2);
    var_plan       NUMBER(3);
    v_param        tparagen.valparam%TYPE := f_obten_parametro_seus('PLA_SAL_INT');
    v_mirex        NUMBER := to_number(dbaper.busca_parametro('PLAN_MIREX', fonos_row.compania));
    v_grupo        VARCHAR2(5);
    v_monto_rec    NUMBER(11, 2);
    CURSOR a IS
    SELECT
        fec_ser,
        estatus,
        plan
    FROM
        reclamacion
    WHERE
            ano = fonos_row.ano_rec
        AND compania = fonos_row.compania
        AND ramo = fonos_row.ramo
        AND secuencial = fonos_row.sec_rec;
      --
    CURSOR b IS
    SELECT
        nvl(MAX(secuencia), 0) + 1
    FROM
        reclamacion_cobertura_salud
    WHERE
            ano = fonos_row.ano_rec
        AND compania = fonos_row.compania
        AND ramo = fonos_row.ramo
        AND secuencial = fonos_row.sec_rec;
      --
    CURSOR c IS
    SELECT
        tip_rec,
        afiliado,
        tip_ser,
        tip_cob,
        cobertura,
        ano_rec,
        compania,
        ramo,
        sec_rec,
        mon_rec,
        mon_pag,
        mon_ded,
        por_coa,
        nvl(tiene_excesoporgrupo, 'N') tiene_excesoporgrupo
    FROM
        infox_session
    WHERE
        numsession = p_numsession;

BEGIN
      --
    fecha_dia := to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
    OPEN c;
    FETCH c INTO
        var_tip_rec,
        var_reclamante,
        var_tip_ser,
        var_tip_cob,
        var_cobertura,
        fonos_row.ano_rec,
        fonos_row.compania,
        fonos_row.ramo,
        fonos_row.sec_rec,
        var_mon_rec,
        var_mon_pag,
        var_mon_ded,
        var_por_coa,
        fonos_row.tiene_excesoporgrupo;

    IF c%found THEN
        OPEN a;
        FETCH a INTO
            var_fec_ser,
            var_estatus,
            var_plan; --<HUMANO TPA> JDEVEAUX  se agrego el var_plan;
        IF a%found THEN
            OPEN b;
            FETCH b INTO var_secuencia;
            CLOSE b;
          --manejo error constraint cobertura , manejado por trigger en tabla rec_c_sal--
            BEGIN
                IF fonos_row.tiene_excesoporgrupo = 'S' THEN
              -- AGREGADO PARA CUANDO EL MONTO NO CUBIERTO SEA POR AGOTAMIENTO DEL GRUPO.
                    var_mon_ded := var_mon_rec - var_mon_pag;
                END IF;
            --

            --Para realizar calculo del monto reclamado por la N frecuencia Miguel A. Carrion 05/05/2022
                IF p_innum1 IS NOT NULL THEN
                    v_monto_rec := var_mon_rec * p_innum1;
                    var_mon_ded := var_mon_ded * p_innum1;
                    var_mon_pag := var_mon_pag * p_innum1;
                END IF;

                INSERT INTO rec_c_sal (
                    ano,
                    compania,
                    ramo,
                    secuencial,
                    secuencia,
                    servicio,
                    tip_cob,
                    cobertura,
                    fec_ser,
                    frecuencia,
                    mon_rec,
                    reserva,
                    estatus,
                    lim_afi,
                    mon_pag,
                    por_coa,
                    tip_rec,
                    reclamante,
                    mon_coaseg,
                    excedente_copago
                ) VALUES (
                    fonos_row.ano_rec,
                    fonos_row.compania,
                    fonos_row.ramo,
                    fonos_row.sec_rec,
                    var_secuencia,
                    var_tip_ser,
                    var_tip_cob,
                    var_cobertura,
                    var_fec_ser,
                    nvl(p_innum1, 1), --Se agrego el parametro para inserta las N frecuencia que se le envie en caso de que venga Null inserta frecuencia 1 Miguel A. Carrion 08/12/2021
                    nvl(v_monto_rec, var_mon_rec),
                    nvl(v_monto_rec, var_mon_rec),
                    var_estatus,
                    var_mon_rec,
                    var_mon_pag,
                    var_por_coa,
                    var_tip_rec,
                    var_reclamante,
                    var_mon_ded,
                    0
                );

            --ACUMULAR CAMPO TOT_MON_DED--
                UPDATE infox_session
                SET
                    tot_mon_ded = nvl(tot_mon_ded, 0) + nvl(var_mon_ded, 0),
                    tiene_excesoporgrupo = 'N' --FClark 4 Jul 22
                WHERE
                    numsession = p_numsession;

            --<84770> jdeveaux --> Se inserta en REC_c_sal_sc
                IF
                    fonos_row.ramo = pkg_const.c_ramo_salud_int
                    AND instr(v_param, ','
                                       || var_plan
                                       || ',') = 0
                    AND fonos_row.tiene_excesoporgrupo = pkg_const.c_no
                THEN
              -- PARA QUE NO ENTRE CUANDO SEA LIMITADO POR GRUPO.
              --
                    INSERT INTO dbaper.rec_c_sal_sc (
                        ano,
                        compania,
                        ramo,
                        secuencial,
                        secuencia,
                        cobertura,
                        tasa,
                        deducible
                    ) VALUES (
                        fonos_row.ano_rec,
                        fonos_row.compania,
                        fonos_row.ramo,
                        fonos_row.sec_rec,
                        var_secuencia,
                        var_cobertura,
                        f_tasa('002', trunc(sysdate), 'C'),
                        var_mon_ded
                    );

                END IF;
            --</84770>

              -- Pregunta para inserta el subgrupo por el cual se realizo la autorizacion de alto Costo  Miguel A. Carrion 10/09/2021
                IF var_tip_ser = to_number(dbaper.busca_parametro('TIP_SERV_CONS_MEDI_0', fonos_row.compania)) THEN
                    INSERT INTO reclamacion_tipo_cobertura (
                        ano,
                        compania,
                        ramo,
                        secuencial,
                        tip_cob,
                        fec_ser,
                        diagnostico
                    ) VALUES (
                        fonos_row.ano_rec,
                        fonos_row.compania,
                        fonos_row.ramo,
                        fonos_row.sec_rec,
                        var_tip_cob,
                        var_fec_ser,
                        dbaper.busca_parametro('DIAGNOSTICO', fonos_row.compania)
                    );

                END IF;
                ---FIN  Miguel A. Carrion 10/09/202


            ------------------------------------------------------------------------------------
            -- Agregado por Leonardo para que cuando la variable V_MIREX sea igual al plan    --
            -- asigne el valor AML a la variable de grupo, de lo contrario se queda como GEN  --
            ------------------------------------------------------------------------------------
                v_grupo := 'GEN';
                IF to_number(v_mirex) = to_number(var_plan) THEN
                    v_grupo := dbaper.val_grupo_x_tip_cob_grupo(var_plan, var_tip_ser, var_tip_cob);
                END IF;
            --<84770> jdeveaux --> Se inserta en RECLAMACION_GRUPO_COBERTURA
            --
                IF
                    fonos_row.ramo = 93
                    AND instr(v_param, ','
                                       || var_plan
                                       || ',') = 0
                THEN
                    DECLARE
                        vdummy VARCHAR2(1);
                --
                        CURSOR c_rgc IS
                        SELECT
                            '1'
                        FROM
                            dbaper.reclamacion_grupo_cobertura
                        WHERE
                                ano = fonos_row.ano_rec
                            AND compania = fonos_row.compania
                            AND ramo = fonos_row.ramo
                            AND secuencial = fonos_row.sec_rec
                            AND grupo_cobertura = v_grupo;

                    BEGIN
                        OPEN c_rgc;
                        FETCH c_rgc INTO vdummy; -- Estabilizacion Salud Internacional. No se dupliquen los grupos al registrar varias coberturas.
                        IF c_rgc%notfound THEN
                            INSERT INTO dbaper.reclamacion_grupo_cobertura (
                                ano,
                                compania,
                                ramo,
                                secuencial,
                                grupo_cobertura,
                                fec_ser,
                                usu_u_ac,
                                fec_u_ac
                            ) VALUES (
                                fonos_row.ano_rec,
                                fonos_row.compania,
                                fonos_row.ramo,
                                fonos_row.sec_rec,
                                v_grupo,
                                fecha_dia,
                                user,
                                sysdate
                            );

                        END IF;

                        CLOSE c_rgc;
                    END;
                END IF;
            --</84770>
                var_code := 0;
          /*EXCEPTION
            WHEN others THEN
              VAR_CODE := 1;*/
            END;

        ELSE
            var_code := 1;
        END IF;

        CLOSE a;
    END IF;

    CLOSE c;
    p_outnum1 := var_code;
END;
