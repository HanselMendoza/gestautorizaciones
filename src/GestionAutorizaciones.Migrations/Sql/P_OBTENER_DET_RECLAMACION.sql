--------------------------------------------------------
--  DDL for Procedure P_OBTENER_DET_RECLAMACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_OBTENER_DET_RECLAMACION" (P_NUMSESSION       IN  INFOX_SESSION.NUMSESSION%TYPE,
                                                                     P_DET_RECLAMACION  OUT SYS_REFCURSOR,
                                                                     P_RESULTADO        OUT NUMBER,
                                                                     P_MENSAJE          OUT VARCHAR2
                                                                    ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento que retora el detalle de la Reclamacion asociada a SESSION consultada.
   * Lorenzo Diaz
   * 06-07-2022
   **************************************************************************************************/    
    
BEGIN 
   IF P_NUMSESSION IS NULL THEN
      P_RESULTADO := 1;
      P_MENSAJE   := 'DEBE DIGITAR UN NUMERO DE SESSION';
      
   ELSE          
       OPEN P_DET_RECLAMACION FOR
       SELECT R.ANO,
              R.COMPANIA,
              R.RAMO,
              R.SECUENCIAL,
              R.SECUENCIA,
              LPAD(R.SERVICIO,4,0)||R.COBERTURA PROC,
              SUM(R.MON_PAG) MONTOARS,
              (SUM(R.MON_REC) - SUM(R.MON_PAG)) MONTOAFILIADO,
              SUM(R.MON_REC) MONTOREC,
              R.FRECUENCIA
         FROM INFOX_SESSION I,
              REC_C_SAL     R
        WHERE I.NUMSESSION = P_NUMSESSION
          --
          AND R.ANO        = I.ANO_REC
          AND R.COMPANIA   = I.COMPANIA
          AND R.RAMO       = I.RAMO
          AND R.SECUENCIAL = I.SEC_REC
        GROUP BY R.ANO, R.COMPANIA, R.RAMO,R.SECUENCIAL,R.SECUENCIA,
                 LPAD(R.SERVICIO,4,0), R.COBERTURA, R.FRECUENCIA;    
                 
         P_RESULTADO := 0;
   
   END IF;
   
   EXCEPTION
     WHEN OTHERS THEN
          P_RESULTADO := 1;
          P_MENSAJE   := SQLERRM;
 
END;

/
