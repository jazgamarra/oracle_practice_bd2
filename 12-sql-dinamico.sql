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

/*
 Cree un procedimiento que reciba por parámetros el código de un empleado que sea jefe
(superior). El procedimiento Deberá armar un sql dinámico que recupero la Cédula, Apellido y
Nombre de todos los empleados que dependen del jefe superior. Prever que el código de jefe sea
variable. Si no se envía como parámetro la cédula de un jefe (si es null), devuelve todos los
empleados. Considere que este ejercicio puede resolverlo también con un cursor estático, o con
un cursor por referencia, pero en este caso en particular, y al solo efecto del ejercicio, utilice el
paquete DBMS_SQL.
 */
-- datos a seleccionar 
SELECT CEDULA, APELLIDO, NOMBRE FROM B_EMPLEADOS WHERE CEDULA_JEFE = 952160; 

-- crear procedimiento que imprima en pantalla los empleados 
CREATE OR REPLACE PROCEDURE P_EMPLEADOS_A_CARGO (P_CEDULA NUMBER DEFAULT NULL) IS
	V_CURSOR NUMBER;
	V_SENTENCIA VARCHAR2(1000);
	v_cantidad NUMBER;
	v_cedula NUMBER; 
	v_apellido VARCHAR2(30); 
	v_nombre VARCHAR2(30); 

BEGIN
	v_cursor := DBMS_SQL.OPEN_CURSOR;
	
	-- definir la sentencia dependiendo de si se tiene o no la cedula como parametro 
	IF P_CEDULA IS NOT NULL THEN 
		v_sentencia := 'SELECT CEDULA, APELLIDO, NOMBRE FROM B_EMPLEADOS WHERE CEDULA_JEFE = (:ced)'; 
		DBMS_SQL.PARSE(v_cursor, v_sentencia, DBMS_SQL.NATIVE);
		DBMS_SQL.BIND_VARIABLE(v_cursor, ':ced', P_CEDULA);	 
	ELSE
		v_sentencia := 'SELECT CEDULA, APELLIDO, NOMBRE FROM B_EMPLEADOS'; 
		DBMS_SQL.PARSE(v_cursor, v_sentencia, DBMS_SQL.NATIVE);
	END IF; 

	-- definir las columnas 
	DBMS_SQL.DEFINE_COLUMN(V_CURSOR, 1, v_cedula);
	DBMS_SQL.DEFINE_COLUMN(V_CURSOR, 2, v_apellido, 30);
	DBMS_SQL.DEFINE_COLUMN(V_CURSOR, 3, v_nombre, 30);
	
	-- ejecutar y recuperar cantidad de filas afectadas 
	v_cantidad := DBMS_SQL.EXECUTE(v_cursor);

	-- imprimir en pantalla todas las filas obtenidas 
	LOOP
        EXIT WHEN DBMS_SQL.FETCH_ROWS(V_CURSOR) = 0;
        DBMS_SQL.COLUMN_VALUE(V_CURSOR, 1, v_cedula);
        DBMS_SQL.COLUMN_VALUE(V_CURSOR, 2, v_apellido);
        DBMS_SQL.COLUMN_VALUE(V_CURSOR, 3, v_nombre);

        DBMS_OUTPUT.PUT_LINE(v_cedula || ' - ' || v_apellido || ', ' || v_nombre);
    END LOOP;
	
	-- ejecutar y cerrar cursor 
	DBMS_SQL.CLOSE_CURSOR(v_cursor);
END; 

-- el procedimiento se puede ejecutar asi 
BEGIN
	P_EMPLEADOS_A_CARGO (952160); 
END; 

-- o asi 
BEGIN
	P_EMPLEADOS_A_CARGO (); 
END; 
