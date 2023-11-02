--------------------------------------------------------
--  DDL for Procedure P_ASEGURADO_TIENE_SOLO_PBS
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_ASEGURADO_TIENE_SOLO_PBS" (P_NUM_PLASTICO   IN  AFILIADO_PLASTICOS.NUM_PLA%TYPE,
                                                                      P_FEC_SER        IN  DATE,
                                                                      P_IND_APLICA     OUT VARCHAR2,
                                                                      P_RESULTADO      OUT NUMBER,
                                                                      P_MENSAJE        OUT VARCHAR2
                                                                      ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento para obtener si el afiliado asociado al plastico aplica al PBS.
   * Lorenzo Diaz
   * 14-06-2022
   **************************************************************************************************/    
    
    
BEGIN
    
   P_IND_APLICA := DBAPER.F_PLAN_BASICO(P_NUM_PLASTICO, TO_DATE(P_FEC_SER,'YYYY-MM-DD'));
   
   P_RESULTADO := 0;
           
EXCEPTION
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
