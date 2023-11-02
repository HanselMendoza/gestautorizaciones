--------------------------------------------------------
--  DDL for Procedure P_DETERMINA_ORIGEN_POR_NUM_PLA
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_DETERMINA_ORIGEN_POR_NUM_PLA" (P_NUM_PLA     IN  NUMBER,
                                                                          P_CODIGO      OUT VARCHAR2,
                                                                          P_RESULTADO   OUT NUMBER,
                                                                          P_MENSAJE     OUT VARCHAR2
                                                                         ) IS
  
 /*
   **************************************************************************************************                                                              
   * Procedimiento para origen por n�mero de pl�stico.
   * Lorenzo Diaz
   * 20-06-2022
   **************************************************************************************************/    
          
BEGIN
  IF P_NUM_PLA IS NOT NULL THEN
  
     P_CODIGO := DBAPER.PKG_ZEUS.DETERMINA_ORIGEN_PRINCIPAL(P_NUM_PLA, NULL, NULL, NULL, NULL);
     
     IF P_CODIGO IS NULL THEN
        P_RESULTADO := 1;
        P_MENSAJE := 'NO EXISTE INFORMACION CON DATO SUMINISTRADO.';
        
     ELSE
        P_RESULTADO := 0;
     
     END IF; 
     
  ELSE
    P_RESULTADO := 1;
    P_MENSAJE := 'DEBE DIGITAR EL DATO DE ENTRADA.';

  END IF;     
              
EXCEPTION       
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
