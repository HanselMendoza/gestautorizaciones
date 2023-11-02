--------------------------------------------------------
--  File created - Wednesday-August-10-2022   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure P_MARCAR_COMO_ARL
--------------------------------------------------------

  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_MARCAR_COMO_ARL" (P_NUMSESSION   IN  NUMBER,
                                                             P_ID_SOLICITUD IN  NUMBER,
                                                             P_RESULTADO    OUT NUMBER,
                                                             P_MENSAJE      OUT VARCHAR2
                                                            ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento para Marcar como ARL.
   * Lorenzo Diaz
   * 14-06-2022
   **************************************************************************************************/    
      
BEGIN
-- El procedure DBAPER.p_crea_solicitud_arl_ivr, no aparece en la base de datos.
  NULL;
EXCEPTION       
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
