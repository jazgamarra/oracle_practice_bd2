/*
Cree un procedimiento que se denomine ‘VERIFICAR ESTATUS’. El procedimiento recibe
como parámetro un nombre de objeto. El procedimiento deberá verificar el estado, y si el mismo
no es válido, deberá proceder a recompilarlo.
La sintaxis para recompilar un objeto es la siguiente
ALTER <tipo_objeto> < nombre_objeto> COMPILE
*/

-- ver el estado de todos los objetos 
SELECT OBJECT_NAME, STATUS, OBJECT_TYPE FROM USER_OBJECTS; 

-- crear el procedimiento 
CREATE OR REPLACE PROCEDURE P_VERIFICAR_STATUS (P_NOMBRE VARCHAR2) IS 
	V_SQL VARCHAR2(100);  
	V_STATUS VARCHAR2(15); 
	V_TIPO VARCHAR2(15);  
BEGIN 
	SELECT STATUS, OBJECT_TYPE INTO V_STATUS, V_TIPO 
	FROM USER_OBJECTS WHERE OBJECT_NAME = P_NOMBRE; 

	IF V_STATUS = 'INVALID' THEN
		V_SQL := 'ALTER ' || V_TIPO || ' ' || P_NOMBRE || ' COMPILE';  -- Corregir V_NOMBRE a P_NOMBRE
		EXECUTE IMMEDIATE V_SQL;
		DBMS_OUTPUT.PUT_LINE('Se recompilo el objeto ' || p_nombre);
	ELSE 
		DBMS_OUTPUT.PUT_LINE('El objeto ' || p_nombre || ' es valido');
	END IF; 
END;

-- probar el procedimiento 
BEGIN
	P_VERIFICAR_STATUS()
END

/*
2. Prepare un procedimiento que recibirá como parámetro una variable booleana que hará lo
siguiente:
 Recuperar con un cursor todos los triggers existentes
 En una variable definir la sentencia SQL apropiada para inhabilitar (en caso que el parámetro
es FALSE), o habilitar (en caso que el parámetro es TRUE), el trigger que recupera el cursor
en ese momento
 Ejecutar la sentencia de inhabilitación/habilitación dinámicamente.
*/

CREATE OR REPLACE PROCEDURE BASEDATOS2.P_ENABLE_DISABLE (P_BOOL BOOLEAN) IS 
	CURSOR C_ALL_TRIGGERS IS 
		SELECT trigger_name FROM USER_TRIGGERS;
	V_SQL VARCHAR2(100); 
	V_ACTION VARCHAR(15); 
BEGIN 
	IF P_BOOL THEN 
		V_ACTION := ' ENABLE'; 
	ELSE
		V_ACTION := ' DISABLE'; 	
	END IF; 
	
	FOR TR IN C_ALL_TRIGGERS LOOP
		V_SQL := 'ALTER TRIGGER ' || TR.TRIGGER_NAME || ' ' || V_ACTION; 
		EXECUTE IMMEDIATE V_SQL;
	END LOOP;
END; 