--------------------------------------------------------
--  DDL for Procedure P_PUEDE_PSS_DAR_SERVICIO
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_PUEDE_PSS_DAR_SERVICIO" (P_TIPO_PSS    IN  VARCHAR2,
                                                                    P_CODIGO_PSS  IN  NUMBER,
                                                                    P_ASEGURADO   IN  NUMBER,
                                                                    P_DEPENDIENTE IN  NUMBER,
                                                                    P_IND_APLICA  OUT VARCHAR2,
                                                                    P_RESULTADO   OUT NUMBER,
                                                                    P_MENSAJE     OUT VARCHAR2
                                                                   ) IS
  
 /*
   **************************************************************************************************                                                              
   * Procedimiento para verificar si PSS puede ofrecer servicios.
   * Lorenzo Diaz
   * 17-06-2022
   **************************************************************************************************/    

   V_SERVCIO_AMB SERVICIO_SALUD.CODIGO%TYPE := F_OBTEN_PARAMETRO_SEUS('TIP_SERV_CONS_MEDI_',F_OBTEN_PARAMETRO_SEUS('COMPANIA_ASEGURADORA',30));
   V_SERVCIO_EMERG SERVICIO_SALUD.CODIGO%TYPE := F_OBTEN_PARAMETRO_SEUS('TIP_SERV_CONS_MEDI_3',F_OBTEN_PARAMETRO_SEUS('COMPANIA_ASEGURADORA',30));
  
  Cursor c_ind_apl is
    SELECT CASE COUNT(A.PLAN)
           WHEN 0
           THEN 'N'
           ELSE 'S'
           END
      FROM dbaper.afi_plan01_v V,
           dbaper.plan_afiliado A
     WHERE A.PLAN        = V.PLAN
       AND V.asegurado   = P_ASEGURADO
       AND V.dependiente = P_DEPENDIENTE
       AND (V.estatus = (SELECT CODIGO
                           FROM ESTATUS
                          WHERE VAL_LOG = 'T'
                            AND TIPO = 'ASE_POL'
                        ) 
            OR V.estatus = (SELECT CODIGO
                            FROM ESTATUS
                           WHERE VAL_LOG = 'T'
                             AND TIPO = 'DEP_POL'
                         )
           )
       AND A.afiliado   = P_CODIGO_PSS
       AND A.tip_afi    = P_TIPO_PSS
       AND A.servicio   IN (V_SERVCIO_AMB,V_SERVCIO_EMERG);

          
BEGIN
  IF P_TIPO_PSS IS NULL 
  OR P_CODIGO_PSS IS NULL 
  OR P_ASEGURADO IS NULL 
  OR P_DEPENDIENTE IS NULL THEN

     P_RESULTADO := 1;
     P_MENSAJE := 'DEBE DIGITAR TODOS LOS DATOS DE ENTRADA.';  
  
  ELSE
     OPEN c_ind_apl;
     FETCH c_ind_apl INTO P_IND_APLICA;
     CLOSE c_ind_apl;
     
     IF P_IND_APLICA IS NULL THEN
        P_RESULTADO := 1;
        P_MENSAJE := 'PARA LOS DATOS SUMINISTRADOS NO APLICA PARA OFRECER SERVICIOS.';
       
     ELSE
        P_RESULTADO := 0;
        
     END IF;
     
  END IF;
            
EXCEPTION       
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
