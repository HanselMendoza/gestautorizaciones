--------------------------------------------------------
--  DDL for Procedure P_COB_REQUIERE_PRESCRIPTOR
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_COB_REQUIERE_PRESCRIPTOR" (P_NUMSESSION     IN  NUMBER,
                                                                      P_SERVICIO       IN  NUMBER, 
                                                                      P_COBERTURA      IN  NUMBER,
                                                                      P_IND_APLICA     OUT VARCHAR2,
                                                                      P_RESULTADO      OUT NUMBER, 
                                                                      P_MENSAJE        OUT VARCHAR2
                                                                    ) IS
                                                                    
 /*
   **************************************************************************************************                                                              
   * Procedimiento para verificar si una cobertura requiere Prescriptor
   * Lorenzo Diaz
   * 18-07-2022
   **************************************************************************************************/                                                                        

    V_SERVICIO_EMERGENCIA       COBERTURA_SALUD.CODIGO%TYPE := F_OBTEN_PARAMETRO_SEUS('EMERGENCIA',30);
    V_ASEGURADO_TIENE_SOLO_PBS  VARCHAR2(1);
    V_ES_LABORATORIO            VARCHAR2(1);
    V_NUM_PLASTICO              INFOX_SESSION.ASE_CARNET%TYPE;
    
BEGIN
    P_IND_APLICA    := 'N';
    P_RESULTADO     := 0;
    
    IF P_NUMSESSION IS NULL OR P_SERVICIO IS NULL OR P_COBERTURA IS NULL
    THEN
        P_RESULTADO := 1;
        P_MENSAJE   := 'Los par�metros P_NUMSESSION, P_SERVICIO y P_COBERTURA son requeridos';
        return;
    END IF;
    
    IF P_SERVICIO <> V_SERVICIO_EMERGENCIA
    THEN
        BEGIN
            SELECT ASE_CARNET
              INTO V_NUM_PLASTICO
              FROM INFOX_SESSION
             WHERE NUMSESSION = P_NUMSESSION;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                P_RESULTADO     := 1;
                P_IND_APLICA    := 'N';
                P_MENSAJE       := 'Sesi�n no existe';
                RETURN;
        END;
        
        AUTORIZACIONES.P_ASEGURADO_TIENE_SOLO_PBS(V_NUM_PLASTICO, SYSDATE, V_ASEGURADO_TIENE_SOLO_PBS, P_RESULTADO, P_MENSAJE);
        IF V_ASEGURADO_TIENE_SOLO_PBS = 'S'
        THEN
            AUTORIZACIONES.P_ES_COBERTURA_LABORATORIO(P_COBERTURA, V_ES_LABORATORIO, P_RESULTADO, P_MENSAJE);
            
            IF V_ES_LABORATORIO = 'S' OR DBAPER.VALIDA_ESTUDIOS_ESPECIALES(P_SERVICIO, P_COBERTURA, NULL) = 1
            THEN
                P_IND_APLICA := 'S';
                RETURN;
            END IF;
        END IF;
    END IF;
EXCEPTION
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
END P_COB_REQUIERE_PRESCRIPTOR;

/
