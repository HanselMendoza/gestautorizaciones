--------------------------------------------------------
--  DDL for Procedure P_OBTENER_NUCLEO_POR_NUM_PLA
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OBTENER_NUCLEO_POR_NUM_PLA" (P_NUM_PLASTICO    IN  NUMBER,
                                                                        P_NUCLEO          OUT SYS_REFCURSOR,
                                                                        P_RESULTADO       OUT NUMBER,
                                                                        P_MENSAJE         OUT VARCHAR2
                                                                       ) IS
  
 /*
   **************************************************************************************************                                                              
   * Procedimiento para obtener n�cleo por n�mero de pl�stico.
   * Lorenzo Diaz
   * 21-06-2022
   **************************************************************************************************/
   
   V_NSS  DBAPER.MAESTRO_AFILIADOS_PDSS.NSS_D%TYPE;
   V_CANT_REG NUMBER := 0;
   
   V_DESC_PLAN VARCHAR2(50) := F_OBTEN_PARAMETRO_SEUS('DESCPLAN',30);  
   
   
              
BEGIN
  IF P_NUM_PLASTICO IS NULL THEN

     P_RESULTADO := 1;
     P_MENSAJE := 'DEBE DIGITAR EL NUMERO DE PLASTICO.';
     
  ELSE
     FOR I IN (
               SELECT * FROM TABLE(DBAPER.f_afiliado_carnet(P_NUM_PLASTICO))
              ) 
     LOOP
        ------------------------------------------------------------------------------------
        -- Capturar el NSS del primer registro
        ------------------------------------------------------------------------------------
        V_CANT_REG := V_CANT_REG + 1;
             
        IF V_CANT_REG = 1 THEN
           V_NSS := I.NSS;
           
        END IF;
        
        ------------------------------------------------------------------------------------
        -- Si el Plan es diferente a PDSS
        ------------------------------------------------------------------------------------
        IF I.DESC_PLAN != V_DESC_PLAN THEN
           BEGIN 
               OPEN P_NUCLEO FOR 
               SELECT B.POLIZA, B.CEDULA, B.NOMBRES, B.APELLIDOS, B.SEXO
                 FROM (
                       SELECT COMPANIA || RAMO || SECUENCIAL AS POLIZA,
                              CED_ACT AS CEDULA,
                              PRI_NOM || ' ' || SEG_NOM AS NOMBRES,
                              PRI_APE || ' ' || SEG_APE APELLIDOS,
                              SEXO
                         FROM DBAPER.ASEDEP_POL02_V
                        WHERE ASEGURADO = I.ASEGURADO
                          AND TRUNC(months_between(sysdate, FEC_NAC) / 12) >= 18
                      ) B;

              P_RESULTADO := 0;
                                  
           EXCEPTION 
             WHEN OTHERS THEN
                P_RESULTADO := 1;
                P_MENSAJE := 'ERROR CUANDO LA DESC_PLAN ES DIFERENTE A PDSS, '||SQLERRM;
                                
           END;
        
        ------------------------------------------------------------------------------------
        -- Si el plan es igual al PDSS y el NSS es nulo
        ------------------------------------------------------------------------------------    
        ELSIF I.DESC_PLAN = V_DESC_PLAN AND I.NSS IS NULL THEN
           BEGIN 
               OPEN P_NUCLEO FOR
               SELECT C.POLIZA, C.CEDULA, C.NOMBRES, C.APELLIDOS, C.SEXO
                 FROM (          
                       SELECT 'PBS' AS POLIZA, 
                               NVL(MT.CEDULA_D, MT.CEDULA_T) AS CEDULA,
                               MT.NOMBRES,
                               MT.APELLIDOS,
                               'M' AS SEXO
                          FROM DBAPER.MAESTRO_AFILIADOS_PDSS MD,
                               DBAPER.MAESTRO_AFILIADOS_PDSS MT
                         WHERE MD.NSS_T = MT.NSS_T
                           AND MD.NSS_D = (SELECT NSS
                                             FROM DBAPER.AFILIADO_PLASTICOS AP,
                                                  DBAPER.ASE_DEP01_V AD
                                            WHERE AD.ASEGURADO = AP.ASEGURADO
                                              AND AD.SECUENCIA = AP.SECUENCIA
                                              AND AP.NUM_PLA   = P_NUM_PLASTICO)
                           AND TO_DATE(MT.FEC_NAC, 'DDMMYYYY') < ADD_MONTHS(TRUNC(SYSDATE), -12*18)                
                     ) C;

              P_RESULTADO := 0;
                              
           EXCEPTION 
             WHEN OTHERS THEN
               P_RESULTADO := 1;
               P_MENSAJE := 'ERROR CUANDO LA DESC_PLAN ES IGUAL A PDSS Y EL NSS ES NULO, '||SQLERRM;
               
           END;

        ELSE
        ------------------------------------------------------------------------------------
        -- Si no es ninguna de las anteriores
        ------------------------------------------------------------------------------------
           BEGIN
               OPEN P_NUCLEO FOR              
               SELECT D.POLIZA, D.CEDULA, D.NOMBRES, D.APELLIDOS, D.SEXO
                 FROM (          
                       SELECT 'PBS' AS POLIZA,
                              NVL(MT.CEDULA_D, MT.CEDULA_T) AS CEDULA,
                              MT.NOMBRES, MT.APELLIDOS,
                              'M' AS SEXO
                         FROM DBAPER.MAESTRO_AFILIADOS_PDSS MD,
                              DBAPER.MAESTRO_AFILIADOS_PDSS MT
                        WHERE MD.NSS_T  = MT.NSS_T
                          AND MD.NSS_D  = V_NSS    -- pasarle ac�, el valor de NSS capturado al principio del loop
                          AND TO_DATE(MT.FEC_NAC, 'DDMMYYYY') < ADD_MONTHS(TRUNC(SYSDATE), -12*18)                           
                      ) D;
                      
             P_RESULTADO := 0;                  
                  
           EXCEPTION
             WHEN OTHERS THEN
               P_RESULTADO := 1;
               P_MENSAJE := 'ERROR CUANDO NO ES NINGUNA DE LAS CONDICIONES, '||SQLERRM;
                               
           END;  
                                   
        END IF;   
          
     END LOOP;
    
  
  END IF; -- Fin si parametro fue digitado   
              
EXCEPTION       
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
