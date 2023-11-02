--------------------------------------------------------
--  DDL for Procedure P_PUEDE_PSS_OFRECER_TIP_COB
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_PUEDE_PSS_OFRECER_TIP_COB" (P_TIPO_PSS   IN  VARCHAR2,
                                                                       P_CODIGO_PSS IN  NUMBER,
                                                                       P_TIP_COB    IN  NUMBER,
                                                                       P_IND_APLICA OUT VARCHAR2,
                                                                       P_RESULTADO  OUT NUMBER,
                                                                       P_MENSAJE    OUT VARCHAR2
                                                                      ) IS
  
 /*
   **************************************************************************************************                                                              
   * Procedimiento para verificar si PSS puede ofrecer tipo de cobertura.
   * Lorenzo Diaz
   * 17-06-2022
   **************************************************************************************************/    
  
  Cursor c_ind_apl is
    SELECT CASE COUNT(LI.CODIGO_PSS)
           WHEN 0
           THEN 'S'
           ELSE 'N'
           END
      FROM DBAPER.LIMITACION_IVR LI 
     WHERE LI.CODIGO_PSS = P_CODIGO_PSS
       AND LI.TIP_PSS    = P_TIPO_PSS
       AND LI.LIMITA_IVR = P_TIP_COB;

 
  V_TIP_REC_NO_MED  RECLAMANTE01_V.TIP_REC%TYPE := F_OBTEN_PARAMETRO_SEUS('TIPO_PSS_NO_MEDICO',F_OBTEN_PARAMETRO_SEUS('COMPANIA_ASEGURADORA',30));
  
  V_TIP_REC_MED  RECLAMANTE01_V.TIP_REC%TYPE := F_OBTEN_PARAMETRO_SEUS('TIPO_PSS_MEDICO',F_OBTEN_PARAMETRO_SEUS('COMPANIA_ASEGURADORA',30));
          
BEGIN
  IF P_TIPO_PSS IS NULL 
  OR P_CODIGO_PSS IS NULL THEN

     P_RESULTADO := 1;
     P_MENSAJE := 'DEBE DIGITAR TODOS LOS DATOS DE ENTRADA.';  
  
  ELSE
     OPEN c_ind_apl;
     FETCH c_ind_apl INTO P_IND_APLICA;
     CLOSE c_ind_apl;
     
     IF P_IND_APLICA IS NULL THEN
        P_RESULTADO := 1;
        P_MENSAJE := 'PARA LOS DATOS SUMINISTRADOS NO APLICA PARA TIPO DE COBERTURA.';
       
     ELSE
        P_RESULTADO := 0;
        
     END IF;
     
  END IF;
            
EXCEPTION       
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
