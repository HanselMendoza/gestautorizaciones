--------------------------------------------------------
--  DDL for Procedure P_DATOS_PRECERTIFICACION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_DATOS_PRECERTIFICACION" (P_TIPO_PSS           IN  VARCHAR2,
                                                                    P_CODIGO_PSS         IN  NUMBER,
                                                                    P_COMPANIA           IN  NUMBER,
                                                                    P_NUM_PRECERT        IN  NUMBER,
                                                                    P_PRECERTIFICACION   OUT SYS_REFCURSOR,
                                                                    P_RESULTADO          OUT NUMBER,
                                                                    P_MENSAJE            OUT VARCHAR2
                                                                   ) IS
  
 /*
   **************************************************************************************************                                                              
   * Procedimiento para obtener datos de Precertificaci�n.
   * Lorenzo Diaz
   * 18-07-2022
   **************************************************************************************************/
   
              
BEGIN
    IF P_TIPO_PSS           IS NULL
        OR P_CODIGO_PSS     IS NULL
        OR P_COMPANIA       IS NULL
        OR P_NUM_PRECERT    IS NULL THEN
        P_RESULTADO := 1;
        P_MENSAJE := 'Los par�metros P_TIPO_PSS, P_CODIGO_PSS, P_COMPANIA, P_NUM_PRECERT son requeridos';
    ELSE
        DBAPER.PKG_PRE_CERTIFICACIONES.P_DATOS_PRECERTIFICACION(P_TIPO_PSS, P_CODIGO_PSS, P_COMPANIA, P_NUM_PRECERT, P_PRECERTIFICACION);
        P_RESULTADO := 0;    
    
    END IF;
        
EXCEPTION
    WHEN OTHERS THEN
        P_RESULTADO := 1;
        P_MENSAJE   := SQLERRM;
        
END;

/
