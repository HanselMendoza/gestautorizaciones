--------------------------------------------------------
--  DDL for Procedure P_CONFIRMAR_RECLAMACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_CONFIRMAR_RECLAMACION" (P_ANO          IN  RECLAMACION.ANO%TYPE,
                                                                   P_COMPANIA     IN  RECLAMACION.COMPANIA%TYPE,
                                                                   P_RAMO         IN  RECLAMACION.RAMO%TYPE,
                                                                   P_SECUENCIAL   IN  RECLAMACION.SECUENCIAL%TYPE,
                                                                   P_CODIGO_PSS   IN  RECLAMACION.RECLAMANTE%TYPE,
                                                                   P_RESULTADO    OUT NUMBER,
                                                                   P_MENSAJE      OUT VARCHAR2
                                                                  ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento para actualizar el estatus de una Reclamacion en especifico.
   * Lorenzo Diaz
   * 14-06-2022
   **************************************************************************************************/    
  
  V_ESTATUS_REC_APERTURADO  ESTATUS.CODIGO%TYPE := F_OBTEN_PARAMETRO_SEUS('ESTRECAPE',P_COMPANIA);      -- ESTATUS APERTURADO
  V_ESTATUS_REC_PREAUTORI   ESTATUS.CODIGO%TYPE := F_OBTEN_PARAMETRO_SEUS('ESTRECPREAUTOR',P_COMPANIA); -- ESTATUS PREAUTORIZADO =  
    
BEGIN

   UPDATE RECLAMACION REC
      SET REC.ESTATUS = V_ESTATUS_REC_APERTURADO
    WHERE REC.ANO        = P_ANO
      AND REC.COMPANIA   = P_COMPANIA
      AND REC.RAMO       = P_RAMO
      AND REC.SECUENCIAL = P_SECUENCIAL
      AND REC.RECLAMANTE = P_CODIGO_PSS
      AND REC.ESTATUS    = V_ESTATUS_REC_PREAUTORI; 

   IF SQL%ROWCOUNT != 0 THEN
      P_RESULTADO := 0;
      
   ELSE
      P_RESULTADO := 1;
      P_MENSAJE := 'RECLAMACION, NO EXISTE.';
      
   END IF;
        
EXCEPTION
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
