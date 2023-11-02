--------------------------------------------------------
--  DDL for Procedure P_ES_PSS_PAQUETE
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_ES_PSS_PAQUETE" (P_CODIGO_PSS  IN  NUMBER,
                                                            P_PIN         IN  NUMBER,
                                                            P_IND_APLICA  OUT VARCHAR2,
                                                            P_RESULTADO   OUT NUMBER,
                                                            P_MENSAJE     OUT VARCHAR2
                                                           ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento para obtener si el afiliado asociado al plastico aplica al PBS.
   * Lorenzo Diaz
   * 14-06-2022
   **************************************************************************************************/    
 
  V_TIP_REC_NO_MED  RECLAMANTE01_V.TIP_REC%TYPE := F_OBTEN_PARAMETRO_SEUS('TIPO_PSS_NO_MEDICO',F_OBTEN_PARAMETRO_SEUS('COMPANIA_ASEGURADORA',30));
  
  V_TIP_REC_MED  RECLAMANTE01_V.TIP_REC%TYPE := F_OBTEN_PARAMETRO_SEUS('TIPO_PSS_MEDICO',F_OBTEN_PARAMETRO_SEUS('COMPANIA_ASEGURADORA',30));
  
  Cursor c_aplica_paq is
    SELECT (CASE WHEN TIP_REC = V_TIP_REC_NO_MED THEN N.PAQUETE ELSE 'N' END) AS PAQUETE
      FROM FONOS_PIN_AFILIADO P, 
           RECLAMANTE01_V R,
           NO_MEDICO N
     WHERE P.AFILIADO  = R.CODIGO 
       AND P.TIP_AFI   = R.TIP_REC
       --
       AND R.CODIGO    = N.CODIGO
       --
       AND P.AFILIADO  = P_CODIGO_PSS 
       AND P.PIN       = P_PIN 
       AND R.ESTATUS   IN (SELECT ES.CODIGO
                             FROM ESTATUS ES
                            WHERE TIPO IN (V_TIP_REC_MED,V_TIP_REC_NO_MED)
                              AND VAL_LOG = 'T'       
                          );
       
        
      
BEGIN
  IF P_CODIGO_PSS IS NULL OR
     P_PIN        IS NULL THEN
     
     P_RESULTADO := 1;
     P_MENSAJE := 'DEBE COLOCAR TODOS LOS PARAMETROS DE BUSQUEDA';
     
  ELSE
      OPEN c_aplica_paq;
      FETCH c_aplica_paq INTO P_IND_APLICA;
      CLOSE c_aplica_paq;  
      
      IF P_IND_APLICA IS NOT NULL THEN
         P_RESULTADO := 0;
         
      ELSE
         P_RESULTADO := 1;
         P_MENSAJE := 'NO EXISTE INFORMACION CON LOS PARAMETROS SUMINISTRADOS.';
         
      END IF;
            
  END IF;           
           
EXCEPTION       
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
