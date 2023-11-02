--------------------------------------------------------
--  DDL for Procedure P_VALIDA_PRECERTIFICACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_VALIDA_PRECERTIFICACION" (P_TIPO_PSS    IN  VARCHAR2,
                                                                     P_CODIGO_PSS  IN  NUMBER,
                                                                     P_COMPANIA    IN  NUMBER,
                                                                     P_NUM_PRECERT IN OUT NUMBER,
                                                                     P_AUTORIZA    OUT VARCHAR2,
                                                                     P_ORIGEN      OUT VARCHAR2,
                                                                     P_OUTNUM      OUT NUMBER,
                                                                     P_RESULTADO   OUT NUMBER, 
                                                                     P_MENSAJE     OUT VARCHAR2
                                                                   ) IS
                                                                    
 /*
   **************************************************************************************************                                                              
   * Procedimiento para valida Precertificaci�n.
   * Lorenzo Diaz
   * 21-07-2022
   **************************************************************************************************/                                                                        

    V_SERVICIO_EMERGENCIA       COBERTURA_SALUD.CODIGO%TYPE := F_OBTEN_PARAMETRO_SEUS('EMERGENCIA',30);
    V_ASEGURADO_TIENE_SOLO_PBS  VARCHAR2(1);
    V_ES_LABORATORIO            VARCHAR2(1);
    V_NUM_PLASTICO              INFOX_SESSION.ASE_CARNET%TYPE;
    
  V_PROGRAMA     VARCHAR2(100);
  V_CODE         VARCHAR2(1000);
  V_ERRM         VARCHAR2(500);
  V_MSG_PROCESO  VARCHAR2(500);    
    
BEGIN
    IF P_TIPO_PSS    IS NULL OR
       P_CODIGO_PSS  IS NULL OR
       P_COMPANIA    IS NULL OR
       P_NUM_PRECERT IS NULL THEN
       P_RESULTADO := 1;
       P_MENSAJE   := 'Los par�metros: P_TIPO_PSS, P_CODIGO_PSS, P_COMPANIA y P_NUM_PRECERT son requeridos.';
       RETURN;
    END IF;
    
    BEGIN
      PKG_PRE_CERTIFICACIONES.P_VALIDA_PRECERTIFICACION(P_TIPO_PSS, P_CODIGO_PSS, P_COMPANIA, P_NUM_PRECERT, P_AUTORIZA, P_ORIGEN, P_OUTNUM);

      IF P_OUTNUM = 3 THEN
         P_RESULTADO     := 0;
         
      ELSE
         P_RESULTADO:= 1;
         P_MENSAJE  := 'No existe PSS';      
      
      END IF;
          
    EXCEPTION
      WHEN OTHERS THEN
         P_RESULTADO:= 1;
         P_MENSAJE  := SQLERRM;
         
         v_programa    := 'AUTORIZACIONES.P_VALIDA_PRECERTIFICACION';
         v_code        := sqlcode;
         v_errm        := substr(sqlerrm, 1, 500);
         v_msg_proceso := 'Error intentando validar la precertificacion';
         pkg_general.p_inserta_error(v_programa, v_code, v_errm, v_msg_proceso);                                    
               
    END;
    
EXCEPTION
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;

       v_programa    := 'AUTORIZACIONES.P_VALIDA_PRECERTIFICACION';
       v_code        := sqlcode;
       v_errm        := substr(sqlerrm, 1, 500);
       v_msg_proceso := 'Error intentando validar la precertificacion';
       pkg_general.p_inserta_error(v_programa, v_code, v_errm, v_msg_proceso);
                                                  
END;

/
