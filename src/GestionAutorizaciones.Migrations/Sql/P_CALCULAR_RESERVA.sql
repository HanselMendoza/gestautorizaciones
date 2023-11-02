--------------------------------------------------------
--  DDL for Procedure P_CALCULAR_RESERVA
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_CALCULAR_RESERVA" (
        lim_afi     IN no_m_cob.limite%TYPE,
        por_des     IN no_m_cob.por_des%TYPE,
        por_coa     IN pol_p_ser.por_coa%TYPE,
        mon_pag     IN OUT rec_c_sal.mon_pag%TYPE,
        mon_por_coa IN OUT infox_session.mon_pag%TYPE,
        p_mon_exe   IN NUMBER,
        p_mon_acum  IN NUMBER
    ) IS
    BEGIN
        IF
            p_mon_exe IS NOT NULL
            AND p_mon_exe <> 0
        THEN
            IF p_mon_acum > p_mon_exe THEN
                mon_por_coa := round((lim_afi * por_coa / 100), 2);
            ELSIF ( p_mon_acum + lim_afi ) > p_mon_exe THEN
                mon_por_coa := round(((((lim_afi + p_mon_acum) - p_mon_exe) * por_coa) / 100), 2);
            END IF;

            mon_pag := ( lim_afi - nvl(mon_por_coa, 0) );
        ELSE
            mon_por_coa := round((lim_afi * por_coa / 100), 2);
            mon_pag := ( lim_afi - nvl(mon_por_coa, 0) );
        END IF;
    END;
