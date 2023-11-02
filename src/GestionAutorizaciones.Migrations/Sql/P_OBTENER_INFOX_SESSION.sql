--------------------------------------------------------
--  DDL for Procedure P_OBTENER_INFOX_SESSION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_OBTENER_INFOX_SESSION" (P_NUMSESSION     IN  DBAPER.INFOX_SESSION.NUMSESSION%TYPE,
                                                                   P_INFOX_SESSION  OUT SYS_REFCURSOR,
                                                                   P_RESULTADO      OUT NUMBER,
                                                                   P_MENSAJE        OUT VARCHAR2) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento que retora los campos en el query.
   * Lorenzo Diaz
   * 05-07-2022
   **************************************************************************************************/    
    
BEGIN 
   OPEN P_INFOX_SESSION FOR
   SELECT D.ESTATUS,
          E.DESCRIPCION DESCRIPCION_ESTATUS,
          D.ES_SOLO_PBS,
          D.ES_PSS_PAQUETE,
          D.TIENE_EXCESOPORGRUPO,
          D.TIP_REC TIPO_PSS,
          D.AFILIADO CODIGO_PSS
     FROM INFOX_SESSION D,
          ESTATUS E
    WHERE E.CODIGO(+) = D.ESTATUS
      AND D.NUMSESSION = P_NUMSESSION;       

     P_RESULTADO := 0;
   
   EXCEPTION
     WHEN OTHERS THEN
          P_RESULTADO := 1;
          P_MENSAJE   := SQLERRM;
 
END;

/
