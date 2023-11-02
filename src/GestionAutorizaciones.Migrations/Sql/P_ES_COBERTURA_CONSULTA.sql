--------------------------------------------------------
--  DDL for Procedure P_ES_COBERTURA_CONSULTA
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_ES_COBERTURA_CONSULTA" (P_COBERTURA  IN  NUMBER,
                                                                   P_IND_APLICA OUT VARCHAR2,
                                                                   P_RESULTADO  OUT NUMBER,
                                                                   P_MENSAJE    OUT VARCHAR2
                                                                 ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento para verificar si cobertura corresponde a Consulta.
   * Lorenzo Diaz
   * 15-06-2022
   **************************************************************************************************/    
 
  V_SERVCIO_AMB SERVICIO_SALUD.CODIGO%TYPE := F_OBTEN_PARAMETRO_SEUS('TIP_SERV_CONS_MEDI_',F_OBTEN_PARAMETRO_SEUS('COMPANIA_ASEGURADORA',30));
  
  Cursor cob_lab is
    SELECT  CASE COUNT(tip_cob)
            WHEN 0 
            THEN 'N'
            ELSE 'S'
            END
      FROM SER_T_COB STC,
           ESTATUS E,
           tip_c_sal TC 
     WHERE STC.ESTATUS    = E.CODIGO
     --
       AND STC.TIP_COB    = TC.CODIGO
       AND STC.SERVICIO   = V_SERVCIO_AMB 
       AND E.VAL_LOG      = 'T'
       AND TC.DESCRIPCION LIKE('%CONSULTA%') 
       AND COBERTURA      = P_COBERTURA;
        
BEGIN
  IF P_COBERTURA IS NOT NULL THEN
     OPEN cob_lab;
     FETCH cob_lab INTO P_IND_APLICA;
     CLOSE cob_lab;
      
     P_RESULTADO := 0;
      
  ELSE
     P_RESULTADO := 1;
     P_MENSAJE := 'DEBE DIGITAR UN CODIGO DE COBERUTA.';
     
  END IF;
            
EXCEPTION       
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
