--------------------------------------------------------
--  DDL for Procedure P_BUSCA_AFILIADO
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_BUSCA_AFILIADO" (P_TIPO_ID         IN  VARCHAR2,
                                                            P_IDENTIFICACION  IN  VARCHAR2,
                                                            P_COMPANIA        IN  NUMBER,
                                                            P_AFILIADO        OUT SYS_REFCURSOR,
                                                            P_RESULTADO       OUT NUMBER,
                                                            P_MENSAJE         OUT VARCHAR2
                                                           ) IS
  
 /*
   **************************************************************************************************                                                              
   * Procedimiento para origen por n�mero de pl�stico.
   * Lorenzo Diaz
   * 20-06-2022
   **************************************************************************************************/
   
    V_NUM_ASEGURADO     NUMBER(15);
    V_NOMBRES           VARCHAR2(100);
    V_PRI_APE           VARCHAR2(50);
    V_SEG_APE           VARCHAR2(50);
    V_SEXO              VARCHAR2(1);
    V_FEC_NAC           DATE;
    V_NACIONALIDAD      VARCHAR2(30);
    V_PARENTESCO        VARCHAR2(40);
    V_COD_EMP           NUMBER(15);
    V_EMPRESA           VARCHAR2(300);
    V_TEL_EMPRESA       VARCHAR2(40);
    V_DIR_EMPRESA       VARCHAR2(300);
    V_ACTIVIDAD         VARCHAR2(100);
    V_TIPO_DOC          VARCHAR2(20);
    V_FEC_SOL           DATE;
    V_CEDULA            VARCHAR2(11);
    V_DESC_PLAN         VARCHAR2(80);
    V_TIPO_PLAN         VARCHAR2(5);
              
BEGIN
  IF P_TIPO_ID IS NULL
  OR P_IDENTIFICACION IS NULL
  OR P_COMPANIA IS NULL THEN

     P_RESULTADO := 1;
     P_MENSAJE := 'DEBE DIGITAR TODOS LOS PARAMETROS DE ENTRADA.';
     
  ELSE   
     
     IF P_TIPO_ID = 'C' THEN     
        IF P_IDENTIFICACION IS NULL THEN
           P_RESULTADO := 1;
           P_MENSAJE := 'DEBE DIGITAR LA IDENTIFICACION DEL AFILIADO.';
           
        ELSE
            dbaper.busca_afiliado_x_cedula(P_TIPO_ID, P_IDENTIFICACION, 
                                           V_NUM_ASEGURADO, V_NOMBRES,  V_PRI_APE,     V_SEG_APE,     V_SEXO,      V_FEC_NAC,  V_NACIONALIDAD, V_PARENTESCO, 
                                           V_COD_EMP,       V_EMPRESA,  V_TEL_EMPRESA, V_DIR_EMPRESA, V_ACTIVIDAD, V_TIPO_DOC, V_FEC_SOL,      V_CEDULA, 
                                           V_DESC_PLAN,     V_TIPO_PLAN
                                          );                                          
           
            IF V_NUM_ASEGURADO IS NULL THEN
               P_RESULTADO := 1;
               P_MENSAJE := 'NO EXISTE NINGUN AFILIADO CON LA IDENTIFICACION PROPORCIONADA.';
            
            ELSE
               OPEN P_AFILIADO FOR         
               select V_NUM_ASEGURADO, V_NOMBRES,  V_PRI_APE,     V_SEG_APE,     V_SEXO,      V_FEC_NAC,  V_NACIONALIDAD, V_PARENTESCO, 
                      V_COD_EMP,       V_EMPRESA,  V_TEL_EMPRESA, V_DIR_EMPRESA, V_ACTIVIDAD, V_TIPO_DOC, V_FEC_SOL,      V_CEDULA, 
                      V_DESC_PLAN,     V_TIPO_PLAN          
                 from dual;                                   
                 
                P_RESULTADO := 0;
                
            END IF; --  Fin si asegurado existe 
                 
        END IF; -- Fin si fueron digitados los parametros de busqueda
                
     ELSE
        IF P_IDENTIFICACION IS NULL 
        OR P_COMPANIA IS NULL THEN 
           P_RESULTADO := 1;
           P_MENSAJE := 'DEBE DIGITAR LA IDENTIFICACION Y LA COMPANIA DEL AFILIADO.';
            
        ELSE
           dbaper.BUSCA_AFILIADO_WS(P_TIPO_ID, P_IDENTIFICACION, P_COMPANIA,
                                    V_NUM_ASEGURADO, V_NOMBRES,  V_PRI_APE,     V_SEG_APE,     V_SEXO,      V_FEC_NAC,  V_NACIONALIDAD, V_PARENTESCO, 
                                    V_COD_EMP,       V_EMPRESA,  V_TEL_EMPRESA, V_DIR_EMPRESA, V_ACTIVIDAD, V_TIPO_DOC, V_FEC_SOL,      V_CEDULA, 
                                    V_DESC_PLAN,     V_TIPO_PLAN
                                   );
           
           IF V_NUM_ASEGURADO IS NULL THEN
              P_RESULTADO := 1;
              P_MENSAJE := 'NO EXISTE NINGUN ASEGURADO CON LA IDENTIFICACION Y COMPANIA PROPORCIONADA.';
                                                  
           ELSE                   
              OPEN P_AFILIADO FOR                                   
              select V_NUM_ASEGURADO, V_NOMBRES,  V_PRI_APE,     V_SEG_APE,     V_SEXO,      V_FEC_NAC,  V_NACIONALIDAD, V_PARENTESCO, 
                     V_COD_EMP,       V_EMPRESA,  V_TEL_EMPRESA, V_DIR_EMPRESA, V_ACTIVIDAD, V_TIPO_DOC, V_FEC_SOL,      V_CEDULA, 
                     V_DESC_PLAN,     V_TIPO_PLAN          
                from dual;
                          
              P_RESULTADO := 0;
              
           END IF; -- Fin si asegurado existe
                
        END IF; -- Fin si fueron digitados los parametros de busqueda
        
     END IF; -- Fin por el tipo de identificacion

  END IF; -- Fin si fueron digitados todos los parametros de busqueda   
              
EXCEPTION       
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
