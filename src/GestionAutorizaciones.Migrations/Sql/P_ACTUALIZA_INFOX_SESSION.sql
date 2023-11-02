--------------------------------------------------------
--  DDL for Procedure P_ACTUALIZA_INFOX_SESSION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_ACTUALIZA_INFOX_SESSION" (P_NUMSESSION           IN  INFOX_SESSION.NUMSESSION%TYPE,
                                                                     P_ESTATUS              IN  INFOX_SESSION.ESTATUS%TYPE,
                                                                     P_ES_SOLO_PBS          IN  INFOX_SESSION.ES_SOLO_PBS%TYPE,
                                                                     P_ES_PSS_PAQUETE       IN  INFOX_SESSION.ES_PSS_PAQUETE%TYPE,
                                                                     P_TIENE_EXCESOPORGRUPO IN  INFOX_SESSION.TIENE_EXCESOPORGRUPO%TYPE,
                                                                     P_RESULTADO            OUT NUMBER,
                                                                     P_MENSAJE              OUT VARCHAR2,                                                                     
                                                                     P_PROCESO              IN  NUMBER DEFAULT NULL,
                                                                     P_ORIGEN               IN  INFOX_SESSION.ORIGEN%TYPE DEFAULT NULL,
                                                                     P_CANAL                IN  INFOX_SESSION.CANAL%TYPE DEFAULT NULL,
                                                                     P_USUARIO_WS           IN  INFOX_SESSION.USUARIO_WS%TYPE DEFAULT NULL,
                                                                     P_API_KEY              IN  INFOX_SESSION.API_KEY%TYPE DEFAULT NULL,
                                                                     P_TOKEN                IN  INFOX_SESSION.TOKEN%TYPE DEFAULT NULL
                                                                    ) IS

 /*
   **************************************************************************************************                                                              
   * Procedimiento que actualiza los datos enviados por parametro.
   * Lorenzo Diaz
   * 05-07-2022
   **************************************************************************************************/    
    
BEGIN 
   IF NVL(P_PROCESO,0) = 0 THEN
      -----------------------------------------------------------------------------------------------
      -- Se actualizan los campos simple de Infox_Session
      -----------------------------------------------------------------------------------------------
       IF  P_ESTATUS              IS NULL
       AND P_ES_SOLO_PBS          IS NULL 
       AND P_ES_PSS_PAQUETE       IS NULL
       AND P_TIENE_EXCESOPORGRUPO IS NULL THEN
          P_RESULTADO := 1;
          P_MENSAJE := 'ALGUNOS DE LOS PARAMETROS DE MODIFICACION DEBE TENER VALOR';
          
       ELSE
          UPDATE INFOX_SESSION XS
             SET XS.ESTATUS              = NVL(P_ESTATUS,XS.ESTATUS),
                 XS.ES_SOLO_PBS          = NVL(P_ES_SOLO_PBS, XS.ES_SOLO_PBS),
                 XS.ES_PSS_PAQUETE       = NVL(P_ES_PSS_PAQUETE, XS.ES_PSS_PAQUETE),
                 XS.TIENE_EXCESOPORGRUPO = NVL(P_TIENE_EXCESOPORGRUPO, XS.TIENE_EXCESOPORGRUPO)
           WHERE XS.NUMSESSION = P_NUMSESSION;
           
          P_RESULTADO := 0;      
           
       END IF;
       
   ELSIF NVL(P_PROCESO,0) = 1 THEN
      -----------------------------------------------------------------------------------------------
      -- Se actualizan los campos de mayor relevancia de Infox_Session
      -----------------------------------------------------------------------------------------------
       IF  P_ORIGEN     IS NULL
       AND P_CANAL      IS NULL
       AND P_USUARIO_WS IS NULL 
       AND P_API_KEY    IS NULL 
       AND P_TOKEN      IS NULL   THEN
           P_RESULTADO := 1;
           P_MENSAJE := 'ALGUNOS DE LOS PARAMETROS DE MODIFICACION DEBE TENER VALOR';
          
       ELSE
          UPDATE INFOX_SESSION XS
             SET XS.ORIGEN      = NVL(P_ORIGEN, XS.ORIGEN),
                 XS.CANAL       = NVL(P_CANAL, XS.CANAL),
                 XS.USUARIO_WS  = NVL(P_USUARIO_WS, XS.USUARIO_WS),
                 XS.API_KEY     = NVL(P_API_KEY, XS.API_KEY),
                 XS.TOKEN       = NVL(P_TOKEN, XS.TOKEN)
           WHERE XS.NUMSESSION = P_NUMSESSION;
           
          P_RESULTADO := 0;      
           
       END IF;      
       
   END IF; -- Fin validando Actualiza default       
   
EXCEPTION
   WHEN OTHERS THEN
        P_RESULTADO := 1;
        P_MENSAJE   := SQLERRM;
 
END;

/
