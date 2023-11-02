--------------------------------------------------------
--  DDL for Procedure P_VALIDA_REGLAS_COBERTURA
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_VALIDA_REGLAS_COBERTURA" (P_NUMSESSION IN  NUMBER,
                                                                     P_SERVICIO   IN  NUMBER,
                                                                     P_COBERTURA  IN  NUMBER,
                                                                     P_IND_APLICA OUT VARCHAR2,
                                                                     P_RESULTADO  OUT NUMBER,
                                                                     P_MENSAJE    OUT VARCHAR2
                                                                   ) IS  

                                                                    
 /*
   **************************************************************************************************                                                              
   * Procedimiento para validar reglas de cobertura
   * Lorenzo Diaz
   * 18-07-2022
   **************************************************************************************************/                                                                        

 V_REQUIERE_PRESCRIPTOR      VARCHAR2(1);
 V_ES_CONSULTA               VARCHAR2(1);
 V_ES_LABORATORIO            VARCHAR2(1);
 V_ASEGURADO_TIENE_SOLO_PBS  VARCHAR2(1);
 V_ES_DOMINGO                VARCHAR2(1);
    
 V_SERVICIO_EMERGENCIA       NUMBER := F_OBTEN_PARAMETRO_SEUS('EMERGENCIA',30);
 V_TIPO_PSS                  VARCHAR2(10);
 V_CODIGO_PSS                NUMBER;
 V_EXISTE_PSS                NUMBER;
 V_NUM_PLASTICO              INFOX_SESSION.ASE_CARNET%TYPE;
    
BEGIN
    IF (P_NUMSESSION IS NULL OR P_SERVICIO IS NULL OR P_COBERTURA IS NULL) THEN
        P_RESULTADO     := 1;
        P_IND_APLICA    := 'N';
        P_MENSAJE       := 'Los par�metros P_NUMSESSION, P_SERVICIO y P_COBERTURA son requeridos';
        RETURN;
        
    END IF;

    BEGIN
        SELECT ASE_CARNET
             , TIP_REC
             , AFILIADO
          INTO V_NUM_PLASTICO
             , V_TIPO_PSS
             , V_CODIGO_PSS
          FROM INFOX_SESSION
         WHERE NUMSESSION = P_NUMSESSION;
         
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_RESULTADO     := 1;
            P_IND_APLICA    := 'N';
            P_MENSAJE       := 'Sesi�n no existe';
            RETURN;
            
        WHEN OTHERS THEN
            P_RESULTADO     := 1;
            P_MENSAJE       := SQLERRM;
            RETURN;
        
    END;
    
    AUTORIZACIONES.P_ASEGURADO_TIENE_SOLO_PBS(V_NUM_PLASTICO, SYSDATE, V_ASEGURADO_TIENE_SOLO_PBS, P_RESULTADO, P_MENSAJE);
    
    IF V_ASEGURADO_TIENE_SOLO_PBS = 'S' AND P_SERVICIO <> V_SERVICIO_EMERGENCIA
    THEN
        AUTORIZACIONES.P_COB_REQUIERE_PRESCRIPTOR(P_NUMSESSION, P_SERVICIO, P_COBERTURA, V_REQUIERE_PRESCRIPTOR, P_RESULTADO, P_MENSAJE);
        AUTORIZACIONES.P_ES_COBERTURA_CONSULTA(P_COBERTURA, V_ES_CONSULTA, P_RESULTADO, P_MENSAJE);
        AUTORIZACIONES.P_ES_COBERTURA_LABORATORIO(P_COBERTURA, V_ES_LABORATORIO, P_RESULTADO, P_MENSAJE);
        
        V_ES_DOMINGO := CASE TRIM(to_char(sysdate, 'DAY')) 
                        WHEN 'SUNDAY' 
                        THEN 'S' 
                        ELSE 'N'
                        END;
        
       
         IF V_REQUIERE_PRESCRIPTOR = 'S' THEN
            P_IND_APLICA    := 'N';
            P_MENSAJE       := 'Debe especificar un m�dico prescriptor de la red';
            RETURN;
                
         ELSIF V_ES_CONSULTA = 'S' THEN
                -- Afiliado agot� consultas ambulatorias
                IF  DBAPER.LIMITE_CONSULTA_MEDICA(V_NUM_PLASTICO) = 0 
                THEN
                    P_IND_APLICA    := 'N';
                    P_MENSAJE       := 'Para autorizar este procedimiento debe contactar al centro de atenci�n al cliente 809-476-3535 opci�n 2.';
                    RETURN;                    
                    
                ELSIF V_ES_DOMINGO = 'S'
                THEN
                    P_IND_APLICA    := 'N';
                    P_MENSAJE       := 'Para autorizar este procedimiento debe contactar al centro de atenci�n al cliente 809-476-3535 opci�n 2.';
                    RETURN;
                    
                END IF;
                    
                -- Es laboratorio o estudio especial
         ELSIF V_ES_LABORATORIO = 'S' OR DBAPER.VALIDA_ESTUDIOS_ESPECIALES(P_SERVICIO, P_COBERTURA, NULL) = 1 THEN 
                    IF V_TIPO_PSS IS NULL OR V_CODIGO_PSS IS NULL
                    THEN 
                        P_RESULTADO := 1;
                        P_MENSAJE   := 'Se desconoce el PSS';
                        RETURN;
                                                
                    END IF;
                    
                    -- AFILIADO TIENE CONSULTAS PREVIAS
                    IF DBAPER.VALIDA_CONSULTA_MEDICA(V_NUM_PLASTICO, NULL, SYSDATE, V_CODIGO_PSS, V_TIPO_PSS) = 1 THEN
                        P_IND_APLICA    := 'N';
                        P_MENSAJE       := 'El asegurado no tiene consultas previas';
                        RETURN;
                        
                    END IF;
                    
         ELSIF DBAPER.VALIDA_SERVICIO_EMERGENCIA(V_NUM_PLASTICO) = 1 THEN
                    P_IND_APLICA    := 'N';
                    P_MENSAJE       := 'El asegurado solo tiene servicio de emergencia ya que es un afiliado nuevo.';
                    RETURN;

         END IF;
                
    END IF;
    
    P_RESULTADO   := 0;
    P_IND_APLICA  := 'S';
    
EXCEPTION
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
       
END P_VALIDA_REGLAS_COBERTURA;

/
