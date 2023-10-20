/*
 1. Cree un bloque PL/SQL anónimo que hará lo siguiente:
	 Definir las variables V_MAXIMO y V_MINIMO.
	 Seleccionar las asignaciones vigentes MAXIMA y MINIMA de los empleados.
	 Imprimir los resultados;
 */

DECLARE 
		V_MAXIMO B_CATEGORIAS_SALARIALES.ASIGNACION%TYPE; 
		V_MINIMO B_CATEGORIAS_SALARIALES.ASIGNACION%TYPE; 
BEGIN 
	SELECT MAX(ASIGNACION), MIN(ASIGNACION) INTO V_MAXIMO, V_MINIMO FROM B_CATEGORIAS_SALARIALES; 
	DBMS_OUTPUT.PUT_LINE('Maximo: ' || to_char(V_MAXIMO) || ' Minimo: ' || to_char(V_MINIMO));
END;
/

/*
 Crear la tabla SECUENCIADOR con las siguientes columnas
- NUMERO NUMBER
- VALOR_PAR VARCHAR2(30)
- VALOR_IMPAR
 Desarrolle un PL/SQL anónimo que permita insertar 100 filas. En la primera columna se insertará el valor del
contador y en la segunda y tercera columnas, el número concatenado con la expresión “es par” o “es impar”
según sea par o impar. Utilice la función MOD.
*/

CREATE TABLE SECUENCIADOR (
	NUMERO NUMBER(8),
	VALOR_PAR VARCHAR2(30),
	VALOR_IMPAR VARCHAR2(30)
); 

DECLARE 
	V_PAR_IMPAR VARCHAR(30);
BEGIN 
	FOR i IN 1 ..10 LOOP 
		IF i MOD 2 = 0 THEN 
			INSERT INTO SECUENCIADOR VALUES (I, i || ' es par.', '-'); 
		ELSE 
			INSERT INTO SECUENCIADOR VALUES (I, '-', i || ' es impar.'); 		
			END IF; 
			COMMIT; 
		END LOOP; 
	END; 
/

/*
Cree un bloque PL/SQL que permita ingresar por teclado, a través de una variable de sustitución, la cédula de un
empleado. Su programa deberá mostrar el nombre y apellido (concatenados), asignación y categoría del empleado
 */
DECLARE 
	TYPE R_EMPLEADO IS RECORD (
	    NOMBRE_APELLIDO VARCHAR2(100),
	    ASIGNACION B_CATEGORIAS_SALARIALES.ASIGNACION%TYPE, 
	    CATEGORIA B_CATEGORIAS_SALARIALES.NOMBRE_CAT%TYPE
  	);
    V_EMP R_EMPLEADO; 
   	V_CEDULA NUMBER := &V_CEDULA; 
BEGIN 
	SELECT EMP.NOMBRE || ' ' || EMP.APELLIDO, CAT.ASIGNACION, CAT.NOMBRE_CAT 
	INTO V_EMP.NOMBRE_APELLIDO, V_EMP.ASIGNACION, V_EMP.CATEGORIA 
	FROM B_EMPLEADOS EMP 
	JOIN B_POSICION_ACTUAL POS ON POS.CEDULA = EMP.CEDULA
	JOIN B_CATEGORIAS_SALARIALES CAT ON CAT.COD_CATEGORIA = POS.COD_CATEGORIA 
	WHERE EMP.CEDULA = V_CEDULA;  
	
	DBMS_OUTPUT.PUT_LINE('Nombre: ' || V_EMP.NOMBRE_APELLIDO);
	DBMS_OUTPUT.PUT_LINE('Asignacion: Gs. ' || V_EMP.ASIGNACION);
	DBMS_OUTPUT.PUT_LINE('Categoria: ' || V_EMP.CATEGORIA);
	
END; 
/

-- para verificar lo que me sale 
SELECT EMP.NOMBRE || ' ' || EMP.APELLIDO, CAT.ASIGNACION, CAT.NOMBRE_CAT 
FROM B_EMPLEADOS EMP 
JOIN B_POSICION_ACTUAL POS ON POS.CEDULA = EMP.CEDULA
JOIN B_CATEGORIAS_SALARIALES CAT ON CAT.COD_CATEGORIA = POS.COD_CATEGORIA 
WHERE EMP.CEDULA = 800909; 





















