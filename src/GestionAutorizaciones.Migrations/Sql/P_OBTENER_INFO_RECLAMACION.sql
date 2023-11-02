--------------------------------------------------------
--  DDL for Procedure P_OBTENER_INFO_RECLAMACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OBTENER_INFO_RECLAMACION" (P_ANO          IN  RECLAMACION.ANO%TYPE,
                                                                      P_COMPANIA     IN  RECLAMACION.COMPANIA%TYPE,
                                                                      P_RAMO         IN  RECLAMACION.RAMO%TYPE,
                                                                      P_SECUENCIAL   IN  RECLAMACION.SECUENCIAL%TYPE,
                                                                      P_CODIGO_PSS   IN  RECLAMACION.RECLAMANTE%TYPE,
                                                                      P_INFO_REC     OUT SYS_REFCURSOR,
                                                                      P_RESULTADO    OUT NUMBER,
                                                                      P_MENSAJE      OUT VARCHAR2) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento que obtiene datos de una Reclamacion en especifico.
   * Lorenzo Diaz
   * 13-06-2022
   **************************************************************************************************/    
  
V_COMPANIA  RECLAMACION.COMPANIA%TYPE;
      
BEGIN
  OPEN P_INFO_REC FOR
    SELECT 
           R.ANO,
           R.COMPANIA,
           R.RAMO,
           R.SECUENCIAL,
           R.USU_ING,
           R.FEC_APE,
           R.ESTATUS,
           E.DESCRIPCION,
           R.NUM_PLA,
           COB.COBERTURA,
           COB_D.DESCRIPCION DESCRIPCION_COBERTURA,
           COB.FRECUENCIA,
           COB.MON_REC,
           COB.MON_PAG,
           COB.MON_COASEG,
           R.TIP_REC,
           R.RECLAMANTE,
           REC.NOMBRE,
           R.TIP_SER,
           E.VAL_L_REC,
           MOT_E.DESCRIPCION DESCRIPCION_RECLAMACION
      FROM RECLAMACION     R,
           RECLAMANTE01_V  REC,
           REC_C_SAL       COB,
           ESTATUS         E,
           COBERTURA_SALUD            COB_D,
           MOTIVO_ESTATUS_RECLAMACION MOT_E
     WHERE R.RECLAMANTE = REC.CODIGO
       AND R.TIP_REC    = REC.TIP_REC
       -- 
       AND R.ANO        = COB.ANO
       AND R.COMPANIA   = COB.COMPANIA
       AND R.RAMO       = COB.RAMO
       AND R.SECUENCIAL = COB.SECUENCIAL
       --
       AND R.ESTATUS = E.CODIGO
       --
       AND COB.COBERTURA = COB_D.CODIGO
       --
       AND MOT_E.CODIGO  = r.motivo_estatus
       --
       AND R.ANO         = NVL(P_ANO,R.ANO) -- OPCIONAL
       AND R.COMPANIA    = P_COMPANIA
       AND R.RAMO        = P_RAMO
       AND R.SECUENCIAL  = P_SECUENCIAL
       AND R.RECLAMANTE  = NVL(P_CODIGO_PSS,R.RECLAMANTE); -- OPCIONAL   

     P_RESULTADO := 0;
   
exception
     WHEN OTHERS THEN
          P_RESULTADO := 1;
          P_MENSAJE   := SQLERRM;
 
END;
