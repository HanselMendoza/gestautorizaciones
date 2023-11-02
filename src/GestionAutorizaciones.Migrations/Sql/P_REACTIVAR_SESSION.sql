--------------------------------------------------------
--  DDL for Procedure P_REACTIVAR_SESSION
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "AUTORIZACIONES"."P_REACTIVAR_SESSION" (P_ANO          IN  NUMBER,
                                                               P_COMPANIA     IN  NUMBER,
                                                               P_RAMO         IN  NUMBER,
                                                               P_RECLAMACION  IN  NUMBER,
                                                               P_NUMSESSION   OUT NUMBER,
                                                               P_RESULTADO    OUT NUMBER,
                                                               P_MENSAJE      OUT VARCHAR2
                                                              ) IS                                                    
-- ******************************************************************** --
-- PRIMERA ARS
-- 06-07-2022
-- Este procedure fue creado en base al procedure P_CREAR_SESSION, para
-- incluirle la busqueda del numsession_origen y el estatus.
-- ******************************************************************** --                                                    

vMAQUINA    VARCHAR2(30);
vRECLAMANTE NUMBER;
vASE_USO    NUMBER;
vCOMPANIA   NUMBER;
vRAMO       NUMBER;
vSEC_POL    NUMBER;
vPLAN       NUMBER;
vTIP_REC    VARCHAR2(50);
vTIP_SER    NUMBER;
vFEC_APE    DATE;
vNUM_PLA    NUMBER;
vDEP_USO    NUMBER;
vUSU_ING    VARCHAR2(50);
vPIN        NUMBER;
vESTATUS           INFOX_SESSION.ESTATUS%TYPE;
vNUMSESSION_ORIGEN INFOX_SESSION.NUMSESSION_ORIGEN%TYPE;


cursor c_seqsession is
select seqsession.nextval from sys.dual;

CURSOR C_MAQUINA IS
  SELECT SUBSTR(MACHINE, 1, 30)
    FROM V$SESSION
   WHERE USERNAME = USER
     AND AUDSID = SYS_CONTEXT('USERENV', 'SESSIONID');

CURSOR C_DATOS IS
  SELECT RECLAMANTE,
         ASE_USO,
         COMPANIA,
         RAMO,
         SEC_POL,
         PLAN,
         TIP_REC,
         TIP_SER,
         FEC_APE,
         NUM_PLA,
         DEP_USO,
         USU_ING
    FROM RECLAMACION
   WHERE ANO = P_ANO
     AND COMPANIA = p_COMPANIA
     AND RAMO = P_RAMO
     AND SECUENCIAL = P_RECLAMACION
     AND INSTR(F_OBTEN_PARAMETRO_SEUS('EST_VIG_REC',30 ), '*' || ESTATUS || '*') > 0;
     
CURSOR C_PIN(pTIP_AFI VARCHAR2, pAFILIADO NUMBER) IS
  SELECT PIN
    FROM FONOS_PIN_AFILIADO
   WHERE TIP_AFI = pTIP_AFI
     AND AFILIADO = pAFILIADO;
     
   CURSOR C_INFO IS
      SELECT MAX(S.NUMSESSION), MAX(S.ESTATUS)
        FROM DBAPER.INFOX_SESSION S
       WHERE S.ANO_REC  = P_ANO
         AND S.COMPANIA = P_COMPANIA
         AND S.RAMO     = P_RAMO
         AND S.SEC_REC  = P_RECLAMACION;        

BEGIN
  IF (P_ANO        IS NULL OR
     P_COMPANIA    IS NULL OR
     P_RAMO        IS NULL OR
     P_RECLAMACION IS NULL) THEN
     P_RESULTADO := 1;
     P_MENSAJE  := 'ALGUNO LOS PARAMETROS DE LA RECLAMACION NO TIENE VALOR.';
     
  ELSE 
    OPEN C_INFO;
    FETCH C_INFO
     INTO vNUMSESSION_ORIGEN, vESTATUS;
    CLOSE C_INFO;
    
    IF NVL(vNUMSESSION_ORIGEN,0) != 0 THEN 
        OPEN C_DATOS;
        FETCH C_DATOS
          INTO vRECLAMANTE,
               vASE_USO,
               vCOMPANIA,
               vRAMO,
               vSEC_POL,
               vPLAN,
               vTIP_REC,
               vTIP_SER,
               vFEC_APE,
               vNUM_PLA,
               vDEP_USO,
               vUSU_ING;
        IF C_DATOS%FOUND THEN
          --
          OPEN C_MAQUINA;
          FETCH C_MAQUINA
            INTO vMAQUINA;
          CLOSE C_MAQUINA;
          --
          OPEN C_PIN(vTIP_REC, vRECLAMANTE);
          FETCH C_PIN
            INTO vPIN;
          CLOSE C_PIN;

          --
          BEGIN
              p_NUMSESSION := SEQSESSION.NEXTVAL;

              INSERT INTO INFOX_SESSION
                (NUMSESSION,
                 INICIO,
                 MAQUINA,
                 AFILIADO,
                 ASEGURADO,
                 RECLAMACION,
                 COMPANIA,
                 RAMO,
                 SECUENCIAL,
                 PLAN,
                 TIP_REC,
                 TIP_SER,
                 PIN,
                 SEC_REC,
                 FEC_APE,
                 ANO_REC,
                 ASE_CARNET,
                 DEPENDIENTE,
                 USUARIO,
                 NUMSESSION_ORIGEN,
                 ESTATUS)
              VALUES
                (p_NUMSESSION,
                 SYSDATE,
                 vMAQUINA,
                 VRECLAMANTE,
                 vASE_USO,
                 P_RECLAMACION,
                 vCOMPANIA,
                 vRAMO,
                 vSEC_POL,
                 vPLAN,
                 vTIP_REC,
                 vTIP_SER,
                 vPIN,
                 P_RECLAMACION,
                 vFEC_APE,
                 P_ANO,
                 vNUM_PLA,
                 vDEP_USO,
                 vUSU_ING,
                 vNUMSESSION_ORIGEN, 
                 vESTATUS);
                 
            P_RESULTADO := 0;
                 
          EXCEPTION
             WHEN OTHERS THEN
                  P_RESULTADO := 1;
                  P_MENSAJE   := SQLERRM; 
                 
          END;
          --
        ELSE
          P_RESULTADO := 1;
          P_MENSAJE   := 'LA RECLAMACION SOLICITADA, NO APLICA PARA REACTIVACION, VERIFICAR ESTATUS RECLAMACION.';
          
        END IF; -- Fin si la reclamacion no aplica para reactivacion
        CLOSE C_DATOS;
            
    ELSE
      P_RESULTADO := 1;
      P_MENSAJE   := 'LA RECLAMACION DIGITADA NO EXISTE O NO TIENE UNA SESSION PREVIA.';
                    
    END IF; -- Fin si vnumsession no existe
    
    COMMIT;
    
  END IF;
    
END;
-- ******************************************************************** --

/
