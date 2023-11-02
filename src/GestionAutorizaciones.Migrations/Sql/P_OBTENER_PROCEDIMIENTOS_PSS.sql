--------------------------------------------------------
--  DDL for Procedure P_OBTENER_PROCEDIMIENTOS_PSS
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OBTENER_PROCEDIMIENTOS_PSS" (P_TIPO_PSS       IN  VARCHAR2,
                                                                        P_CODIGO_PSS     IN  NUMBER,
                                                                        P_PROCEDIMIENTOS OUT SYS_REFCURSOR, --AUTORIZACIONES.PROCEDIMIENTOS_PSS_SET,
                                                                        P_RESULTADO      OUT NUMBER,
                                                                        P_MENSAJE        OUT VARCHAR2
                                                                       ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento para verificar si cobertura corresponde a Consulta.
   * Lorenzo Diaz
   * 15-06-2022
   **************************************************************************************************/    
 
  V_TIP_REC_NO_MED  RECLAMANTE01_V.TIP_REC%TYPE := F_OBTEN_PARAMETRO_SEUS('TIPO_PSS_NO_MEDICO',F_OBTEN_PARAMETRO_SEUS('COMPANIA_ASEGURADORA',30));
  
  V_TIP_REC_MED  RECLAMANTE01_V.TIP_REC%TYPE := F_OBTEN_PARAMETRO_SEUS('TIPO_PSS_MEDICO',F_OBTEN_PARAMETRO_SEUS('COMPANIA_ASEGURADORA',30));
          
BEGIN
  IF P_TIPO_PSS IS NULL 
  OR P_CODIGO_PSS IS NULL THEN

     P_RESULTADO := 1;
     P_MENSAJE := 'DEBE DIGITAR TODOS LOS DATOS DE ENTRADA.';  
  
  ELSE
     IF P_TIPO_PSS = V_TIP_REC_MED THEN
        -----------------------------------------------------------------------------------------------------------
        -- MEDICO
        -----------------------------------------------------------------------------------------------------------
        BEGIN           
            OPEN P_PROCEDIMIENTOS FOR
            select v.CODIGO , v.nombre, v.tipo, v.SERVICIO, v.tipo_servicio, v.COBERTURA, v.nombre_cobertura
              from (
                    select distinct a.CODIGO as codigo, a.PRI_NOM||' '||a.PRI_APE as nombre, 'MEDICO' as tipo,
                           ' ' as SERVICIO, ' ' as tipo_servicio, COBERTURA, e.DESCRIPCION as nombre_cobertura 
                      from medico a,
                           medico_especialidad_cobertura c,
                           cob_sal e
                     where a.estatus = (select codigo
                                          from estatus
                                         where val_log = 'T'
                                           and tipo = V_TIP_REC_MED
                                       )
                       and a.codigo  = c.medico
                       and e.codigo  = c.cobertura
                       and a.codigo  = P_CODIGO_PSS
                    ) v;
            
            P_RESULTADO := 0;   
               
        EXCEPTION
           WHEN OTHERS THEN
                P_RESULTADO := 1;
                P_MENSAJE := 'SQLERRM';
               
        END;
        
     ELSIF P_TIPO_PSS = V_TIP_REC_NO_MED THEN
        -----------------------------------------------------------------------------------------------------------
        -- NO  MEDICO
        -----------------------------------------------------------------------------------------------------------     
        BEGIN
            OPEN P_PROCEDIMIENTOS FOR
            select v.codigo, v.nombre, v.tipo, v.servicio, v.tipo_servicio, v.cobertura, v.nombre_cobertura
              from (
                    select distinct a.codigo, a.nombre, b.descripcion tipo, d.descripcion servicio,
                           f.descripcion tipo_servicio, c.cobertura, e.descripcion nombre_cobertura
                      from no_medico a,
                           tip_n_med b,
                           no_medico_cobertura c,
                           ser_sal d,
                           cob_sal e,
                           tip_c_sal f
                     where a.estatus   = (select codigo
                                            from estatus
                                           where val_log = 'T'
                                             and tipo = V_TIP_REC_NO_MED
                                       )
                       and f.codigo    = c.tip_cob
                       and a.codigo    = c.no_med
                       and a.tip_n_med = b.codigo
                       and d.codigo    = c.servicio
                       and e.codigo    = c.cobertura
                       and d.codigo    = 1        
                       and a.codigo    = P_CODIGO_PSS
                     ) v;
               
           P_RESULTADO := 0;
               
        EXCEPTION
          WHEN OTHERS THEN
               P_RESULTADO := 1;
               P_MENSAJE   := SQLERRM;        
                
        END;           
          
     END IF;
     
  END IF;
            
EXCEPTION       
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
