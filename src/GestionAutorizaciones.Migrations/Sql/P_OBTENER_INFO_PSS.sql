--------------------------------------------------------
--  DDL for Procedure P_OBTENER_INFO_PSS
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OBTENER_INFO_PSS" (P_TIPO_PSS   IN  MED_N_MED01_V.TIP_MED%TYPE,
                                                              P_CODIGO_PSS IN  MED_N_MED01_V.CODIGO%TYPE,
                                                              P_INFO_PSS   OUT SYS_REFCURSOR, --AUTORIZACIONES.PRESTADOR_SET,
                                                              P_RESULTADO  OUT NUMBER,
                                                              P_MENSAJE    OUT VARCHAR2) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento que obtiene datos de un Proveedor en especifico Medico o No Medico.
   * Lorenzo Diaz
   * 10-06-2022
   **************************************************************************************************/    
  
V_TIP_REC  RECLAMANTE01_V.TIP_REC%TYPE;
      
BEGIN 
  OPEN P_INFO_PSS FOR
   SELECT 
          R.TIP_REC, 
          R.TIPO,
          R.CODIGO,
          R.NOMBRE,
          R.CED_ACT,
          R.ESTATUS, 
          E.DESCRIPCION,
          E.VAL_L_REC,
          R.RNC, 
          R.FEC_ING, 
          R.FEC_SAL,
          R.ARS
     FROM RECLAMANTE01_V R,
          ESTATUS E
    WHERE R.ESTATUS = E.CODIGO
      AND R.CODIGO  = P_CODIGO_PSS
      AND R.TIP_REC = P_TIPO_PSS;       

   -- Validamos exceciones  
--   BEGIN
--       SELECT TIP_REC
--         INTO V_TIP_REC
--         FROM TABLE (P_INFO_PSS)
--       WHERE CODIGO = P_CODIGO_PSS
--         AND TIP_REC = P_TIPO_PSS;
-- 
--     P_RESULTADO := 0;
--   
--   EXCEPTION
--     WHEN OTHERS THEN
--          P_RESULTADO := 1;
--          P_MENSAJE   := SQLERRM;
--   
--   END;

     P_RESULTADO := 0;
   
   EXCEPTION
     WHEN OTHERS THEN
          P_RESULTADO := 1;
          P_MENSAJE   := SQLERRM;
 
END;
