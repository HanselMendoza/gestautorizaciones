--------------------------------------------------------
--  DDL for Procedure P_OBTENER_RECLAMACIONES_PSS
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OBTENER_RECLAMACIONES_PSS" (P_TIPO_PSS      IN  RECLAMACION.TIP_REC%TYPE,
                                                                       P_CODIGO_PSS    IN  RECLAMACION.RECLAMANTE%TYPE,
                                                                       P_FECHA_INICIO  IN  DATE,
                                                                       P_FECHA_FIN     IN  DATE,
                                                                       P_RAMO          IN  RECLAMACION.RAMO%TYPE,
                                                                       P_SECUENCIAL    IN  RECLAMACION.SECUENCIAL%TYPE,
                                                                       P_USU_ING       IN  RECLAMACION.USU_ING%TYPE,
                                                                       P_NUM_PLASTICO  IN  RECLAMACION.NUM_PLA%TYPE,                                                                       
                                                                       P_RECLAMACIONES OUT SYS_REFCURSOR, --AUTORIZACIONES.RECLAMACION_PSS_SET,
                                                                       P_RESULTADO     OUT NUMBER,
                                                                       P_MENSAJE       OUT VARCHAR2
                                                                      ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento que obtiene datos de una Reclamacion en especifico.
   * Lorenzo Diaz
   * 13-06-2022
   **************************************************************************************************/    

  V_ANO       RECLAMACION.ANO%TYPE := TO_NUMBER(TO_CHAR(P_FECHA_INICIO,'YYYY'));  
    
BEGIN
  IF P_TIPO_PSS IS NULL OR 
     P_CODIGO_PSS IS NULL OR 
     P_FECHA_INICIO IS NULL OR
     P_FECHA_FIN IS NULL THEN
       P_RESULTADO := 1;
       P_MENSAJE := 'ALGNOS DE LOS PARAMETROS REQUERIDOS ESTA NULO';
       
  ELSE
   BEGIN     
       OPEN P_RECLAMACIONES FOR
        SELECT 
               R.ANO,
               R.COMPANIA,
               R.RAMO,
               R.SECUENCIAL,
               R.USU_ING,
               R.TIP_SER, 
               R.FEC_APE,
               R.ESTATUS,
               R.NUM_PLA,
               SUM(C.MON_REC), 
               SUM(C.MON_PAG),
               SUM(C.MON_COASEG)
          FROM RECLAMACION R,
               REC_C_SAL C
         WHERE R.ANO        = C.ANO
           AND R.COMPANIA   = C.COMPANIA
           AND R.RAMO       = C.RAMO
           AND R.SECUENCIAL = C.SECUENCIAL
           AND R.ANO        = V_ANO
           AND R.FEC_SER   >= P_FECHA_INICIO AND R.FEC_SER <= P_FECHA_FIN       
           AND R.TIP_REC    = P_TIPO_PSS
           AND R.RECLAMANTE = P_CODIGO_PSS
           AND R.ESTATUS   != F_OBTEN_PARAMETRO_SEUS('ESTATUS_TRANSITORIO',C.COMPANIA)
           AND R.RAMO       = NVL(P_RAMO,R.RAMO) -- OPCIONAL
           AND R.SECUENCIAL = NVL(P_SECUENCIAL,R.SECUENCIAL) -- OPCIONAL
           AND R.USU_ING    = NVL(P_USU_ING,R.USU_ING) -- OPCIONAL
           AND R.NUM_PLA    = NVL(P_NUM_PLASTICO,R.NUM_PLA) -- OPCIONAL
         GROUP BY R.ANO, R.COMPANIA, R.RAMO, R.SECUENCIAL, R.USU_ING, R.TIP_SER, R.FEC_APE, R.ESTATUS, R.NUM_PLA;

         P_RESULTADO := 0;
                
   EXCEPTION
     WHEN OTHERS THEN
          P_RESULTADO := 1;
          P_MENSAJE   := SQLERRM;   
   
   END;
   
  END IF;
    
exception
     WHEN OTHERS THEN
          P_RESULTADO := 1;
          P_MENSAJE   := SQLERRM;
 
END;
