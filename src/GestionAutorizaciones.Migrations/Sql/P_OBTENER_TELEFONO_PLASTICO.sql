--------------------------------------------------------
--  DDL for Procedure P_OBTENER_TELEFONO_PLASTICO
--------------------------------------------------------


  CREATE OR REPLACE PROCEDURE "P_OBTENER_TELEFONO_PLASTICO" (P_NUM_PLASTICO   IN  AFILIADO_PLASTICOS.NUM_PLA%TYPE,
                                                                       P_TELEFONO       OUT VARCHAR2,
                                                                       P_RESULTADO      OUT NUMBER,
                                                                       P_MENSAJE        OUT VARCHAR2
                                                                      ) IS
 
 /*
   **************************************************************************************************                                                              
   * Procedimiento para obtener el telefono mas reciente ordenado en orden descendente.
   * Lorenzo Diaz
   * 14-06-2022
   **************************************************************************************************/    
    
  Cursor telef is
    select t.telefono
      from dbaper.telefono t,
           dbaper.afiliado_plasticos c
     where t.propietario = c.asegurado
       and c.num_pla     = p_num_plastico
     order by t.codigo desc;
    
BEGIN
    
   Open telef;
   fetch telef into P_TELEFONO;
   close telef;
   
   if p_telefono is null then
      P_RESULTADO := 1;
      P_MENSAJE := 'NO TIENE TELEFONO';
      
   else
      P_RESULTADO := 0;
      
   end if;

        
EXCEPTION
  WHEN OTHERS THEN
       P_RESULTADO := 1;
       P_MENSAJE   := SQLERRM;
    
END;
