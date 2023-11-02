--------------------------------------------------------
--  DDL for Procedure P_OBTENER_TIPO_PSS
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OBTENER_TIPO_PSS" (P_CODIGO_PSS    IN  FONOS_PIN_AFILIADO.AFILIADO%TYPE,
                                                              P_PIN           IN  FONOS_PIN_AFILIADO.PIN%TYPE,
                                                              P_TIPO_PSS      OUT FONOS_PIN_AFILIADO.TIP_AFI%TYPE,
                                                              P_RESULTADO     OUT NUMBER,
                                                              P_MENSAJE       OUT VARCHAR2
                                                             ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento que obtiene el Tipo de PSS de un afiliado en base a su pin.
   * Lorenzo Diaz
   * 14-06-2022
   **************************************************************************************************/    
 
  Cursor C_TIPO_PSS is
     SELECT TIP_AFI 
       FROM FONOS_PIN_AFILIADO
      WHERE AFILIADO = P_CODIGO_PSS 
        AND PIN      = P_PIN;
    
BEGIN
   OPEN C_TIPO_PSS;
   FETCH C_TIPO_PSS INTO P_TIPO_PSS;
   CLOSE C_TIPO_PSS;
   
   IF P_TIPO_PSS IS NULL THEN
      P_RESULTADO := 1;
      P_MENSAJE := 'NO EXISTEN DATOS PARA LOS PARAMETROS ENVIADOS.';
        
   ELSE
      P_RESULTADO := 0;
        
   END IF;
   
exception
     WHEN OTHERS THEN
          P_RESULTADO := 1;
          P_MENSAJE   :=' QUERY PRINCIPAL, '|| SQLERRM;
 
END;
