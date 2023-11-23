/*  
1. Cree en la BD el tipo T_CLIENTE que tiene los siguientes elementos:
Los atributos
	CEDULA-RUC VARCHAR2(15),
	NOMBRE VARCHAR2(40),
	APELLIDO VARCHAR2(40),
	TELÉFONO VARCHAR2(40),
	DIRECCIÓN VARCHAR2(40)
	MONTO_VENTAS NUMBER
Y los siguientes métodos
	 Función Nombre_compuesto : Devuelve el apellido y el nombre del cliente concatenados en un varchar2
	 La función estática Asignar_cliente , que recibe como parámetro una cédula (o ruc), y devuelve una
	variable de tipo T_CLIENTE instanciada con datos del cliente (busca por la cédula o el RUC). Recuerde
	que los métodos estáticos no tienen variables SELF.
	 Un método ORDER para el correspondiente ordenamiento de los clientes
 */

-- crear la cabecera del objeto 
CREATE OR REPLACE TYPE T_CLIENTE AS OBJECT (
	CEDULA_RUC VARCHAR2(15),
	NOMBRE VARCHAR2(40),
	APELLIDO VARCHAR2(40),
	TELEFONO VARCHAR2(40),
	DIRECCION VARCHAR2(40),
	MONTO_VENTAS NUMBER, 
	
	MEMBER FUNCTION NOMBRE_COMPUESTO RETURN VARCHAR2, 
	STATIC FUNCTION ASIGNAR_CLIENTE(CEDULA_RUC IN VARCHAR2) RETURN T_CLIENTE, 
	ORDER MEMBER FUNCTION orden_cli (cli1 T_CLIENTE) RETURN NUMBER
);

-- crear el cuerpo del objeto 
CREATE OR REPLACE TYPE BODY T_CLIENTE AS

	  -- funcion nombre_compuesto 
	  MEMBER FUNCTION NOMBRE_COMPUESTO RETURN VARCHAR2 IS
	  BEGIN
	    	RETURN SELF.APELLIDO || ' ' || SELF.NOMBRE;
	  END;
	
	 -- funcion estatica asignar_cliente 
	  	STATIC FUNCTION ASIGNAR_CLIENTE(CEDULA_RUC IN VARCHAR2) RETURN T_CLIENTE IS
		    CLIENTE_RESULTADO T_CLIENTE := T_CLIENTE('', '', '', '', '', 0);
		    ES_CEDULA BOOLEAN := false;
		BEGIN
		    -- Verificar si CEDULA_RUC es una cédula o un RUC
		    IF REGEXP_LIKE(CEDULA_RUC, '^\d+$') THEN
		        ES_CEDULA := true;
		    END IF;
		
		    -- Consulta basada en el tipo de identificación
		    IF ES_CEDULA THEN
		        SELECT CEDULA, NOMBRE, APELLIDO, TELEFONO, DIRECCION
		        INTO CLIENTE_RESULTADO.CEDULA_RUC, CLIENTE_RESULTADO.NOMBRE, 
		        CLIENTE_RESULTADO.APELLIDO, CLIENTE_RESULTADO.TELEFONO, CLIENTE_RESULTADO.DIRECCION
		        FROM B_PERSONAS
		        WHERE ES_CLIENTE = 'S'
		        AND CEDULA = TO_NUMBER(CEDULA_RUC);
		    ELSE
		        SELECT RUC, NOMBRE, APELLIDO, TELEFONO, DIRECCION
		        INTO CLIENTE_RESULTADO.CEDULA_RUC, CLIENTE_RESULTADO.NOMBRE, 
		        CLIENTE_RESULTADO.APELLIDO, CLIENTE_RESULTADO.TELEFONO, CLIENTE_RESULTADO.DIRECCION
		        FROM B_PERSONAS
		        WHERE ES_CLIENTE = 'S'
		        AND RUC = CEDULA_RUC;
		    END IF;
		
		    RETURN CLIENTE_RESULTADO;
		END;

	 -- funcion order 
	  ORDER MEMBER FUNCTION orden_cli(cli1 T_CLIENTE) RETURN NUMBER IS
	  BEGIN
	    -- Comparamos los nombres compuestos de los clientes
	    IF self.NOMBRE_COMPUESTO < cli1.NOMBRE_COMPUESTO THEN
	      RETURN -1;
	    ELSIF self.NOMBRE_COMPUESTO = cli1.NOMBRE_COMPUESTO THEN
	      RETURN 0;
	    ELSE
	      RETURN 1;
	    END IF;
	  END;
END;

-- probar los metodos jeje 
	DECLARE
		NuevoCliente T_CLIENTE;
		NuevoCliente2 T_CLIENTE;
	BEGIN
		NuevoCliente := T_CLIENTE.ASIGNAR_CLIENTE(429987);
		DBMS_OUTPUT.PUT_LINE('Cliente encontrado: ' || NuevoCliente.NOMBRE_COMPUESTO());
	
		NuevoCliente2 := T_CLIENTE.ASIGNAR_CLIENTE(1207876);
		DBMS_OUTPUT.PUT_LINE('Cliente encontrado: ' || NuevoCliente2.NOMBRE_COMPUESTO());
	
		DBMS_OUTPUT.PUT_LINE('Comparacion: ' || NuevoCliente2.orden_cli(NuevoCliente));
		DBMS_OUTPUT.PUT_LINE('Comparacion: ' || NuevoCliente.orden_cli(NuevoCliente));
		DBMS_OUTPUT.PUT_LINE('Comparacion: ' || NuevoCliente.orden_cli(NuevoCliente2));
	END;

/*
2. Cree la tabla TAB_CLIENTE conformada por objetos de tipo T_CLIENTE.
Desarrolle un PL/SQL anónimo que deberá leer los clientes (personas clientes) secuencialmente, y los
inserte en la tabla TAB_CLIENTE (recuerde usar el método estático para asignar clientes).
Leer nuevamente la tabla e imprimir los datos:
CÉDULA_RUC, NOMBRE_COMPUESTO (a través del método).
*/	

-- crear la tabla 
CREATE TABLE TAB_CLIENTES (
	ID NUMBER,
	CLIENTE T_CLIENTE
); 

-- crear una secuencia para el id de la tabla 
CREATE SEQUENCE s_tab_clientes_id
	INCREMENT BY 1
	START WITH 1
	MAXVALUE 9999999
	NOCACHE
	NOCYCLE;

-- ingresar los valores 
DECLARE 
	CURSOR C_CLIENTES IS 
		SELECT NVL(CEDULA, RUC) CEDULA_RUC FROM B_PERSONAS WHERE ES_CLIENTE = 'S';
		NUEVO_CLIENTE T_CLIENTE; 
BEGIN 
	FOR CLI IN C_CLIENTES LOOP
		NUEVO_CLIENTE := T_CLIENTE.ASIGNAR_CLIENTE(CLI.CEDULA_RUC); 
		INSERT INTO TAB_CLIENTES VALUES (s_tab_clientes_id.NEXTVAL, NUEVO_CLIENTE); 
		DBMS_OUTPUT.PUT_LINE( 'Se agrego al cliente ' || NUEVO_CLIENTE.NOMBRE_COMPUESTO());
	END LOOP;
END;

-- consultar la tabla 
SELECT * FROM TAB_CLIENTES; 

/*
3. Cree la tabla VENTAS con una de las columnas conformada por objetos T_CLIENTE de la siguiente manera:
	ID_ARTICULO NUMBER(8),
	 CANTIDAD NUMBER(9),
	 MONTO NUMBER(9),
	 DATOS_CLIENTE T_CLIENTE

Cree un procedimiento que reciba como parámetros el id del artículo, la cantidad y cédula del_cliente. El
procedimiento deberá validar que el id del artículo exista en la tabla B_ARTICULOS y obtendrá el
precio para calcular el ‘monto’. También deberá validar que cliente exista en la tabla TAB_CLIENTE, y
deberá obtener los datos del CLIENTE. Finalmente con los datos obtenidos, el procedimiento deberá
insertar un registro en la tabla VENTAS.
 */

-- crear la tabla 
CREATE TABLE VENTAS (
	ID_ARTICULO NUMBER(8),
	CANTIDAD NUMBER(9),
	MONTO NUMBER(9),
	DATOS_CLIENTE T_CLIENTE
); 

-- crear el procedimiento 
CREATE OR REPLACE PROCEDURE INSERTAR_VENTA (P_ID_ART NUMBER, P_CANTIDAD NUMBER, P_CEDULA VARCHAR2) 
IS 
	V_PRECIO NUMBER; 
	V_CLIENTE T_CLIENTE := T_CLIENTE('', '', '', '', '', 0); 
BEGIN
	-- validar si existe el articulo
	BEGIN 
		SELECT PRECIO INTO V_PRECIO FROM B_ARTICULOS WHERE ID = P_ID_ART; 
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR (-20001, '(!!!) No se encontro un articulo con ese ID'); 
	END; 

	-- validar si existe la persona 
	BEGIN 
 		SELECT CLIENTE
 		INTO V_CLIENTE
 		FROM TAB_CLIENTES c
 		WHERE c.CLIENTE.CEDULA_RUC = P_CEDULA; 
 	EXCEPTION 
		WHEN _FOUND THEN
			RAISE_APPLICATION_ERROR (-20002, '(!!!) No se encontro un cliente con esa cedula'); 
	END; 

	-- insertar en la tabla ventas 
	INSERT INTO VENTAS VALUES (P_ID_ART, P_CANTIDAD, V_PRECIO * P_CANTIDAD, V_CLIENTE); 
	COMMIT; 
END;

-- probar el procedimiento 
BEGIN 
	INSERTAR_VENTA(123456, 10, 429987); 
END; 

-- verificar la tabla ventas 
SELECT * FROM ventas; 

/*
Cree el tipo T_DEUDORES con los siguientes elementos:
	ID_CLIENTE
	NOMBRE (Nombre y apellido)
	DEUDA_TOTAL
	DEUDA_VENCIDA
Y los siguientes métodos:
	 Un método estático denominado OBTENER_CLIENTE que reciba como parámetro una cédula o
	RUC del cliente y devuelva un objeto del tipo T_DEUDORES que tenga asignado el ID del
	cliente y el nombre (nombre concatenado con apellido)
	 El método miembro OBTENER_DEUDA que asigna el atributo DEUDA_TOTAL con la suma
	del monto de todas las cuotas de ventas a crédito pendientes de pago, y el atributo
	DEUDA_VENCIDA con la suma de todas las cuotas ya vencidas pendientes de pago.
	 Un método MAP que ordene por ID del cliente
*/

CREATE OR REPLACE TYPE T_DEUDORES AS OBJECT (
	ID_CLIENTE NUMBER,
	NOMBRE VARCHAR2(50), 
	DEUDA_TOTAL NUMBER,
	DEUDA_VENCIDA NUMBER, 
	STATIC FUNCTION OBTENER_CLIENTE (CEDULA_RUC IN VARCHAR2) RETURN T_DEUDORES, 
	MEMBER PROCEDURE OBTENER_DEUDA
); 


CREATE OR REPLACE TYPE BODY T_DEUDORES AS 
	STATIC FUNCTION OBTENER_CLIENTE (CEDULA_RUC IN VARCHAR2) RETURN T_DEUDORES IS 	
		V_CLIENTE T_DEUDORES := T_DEUDORES(0, '', 0, 0); 
		ES_CEDULA BOOLEAN := false;
	BEGIN 	
		-- Verificar si CEDULA_RUC es una cédula o un RUC
	    IF REGEXP_LIKE(CEDULA_RUC, '^\d+$') THEN
	        ES_CEDULA := true;
	    END IF;
	
	    -- Consulta basada en el tipo de identificación
	    IF ES_CEDULA THEN
	    	SELECT id, nombre || ' ' || apellido 
	    	INTO v_cliente.id_cliente, v_cliente.nombre
	    	FROM B_PERSONAS WHERE cedula = cedula_ruc;     
	    ELSE
	        SELECT id, nombre || ' ' || apellido 
	    	INTO v_cliente.id_cliente, v_cliente.nombre
	    	FROM B_PERSONAS WHERE ruc = cedula_ruc;  
	    END IF;
	END; 

	MEMBER PROCEDURE OBTENER_DEUDA IS
	BEGIN 
		SELECT
		  SUM(CASE WHEN PPA.FECHA_PAGO IS NULL THEN PPA.MONTO_CUOTA ELSE 0 END) DEUDA_TOTAL, 
		  SUM(CASE WHEN PPA.FECHA_PAGO IS NULL AND PPA.VENCIMIENTO < SYSDATE THEN PPA.MONTO_CUOTA ELSE 0 END) DEUDA_VENCIDA 
		INTO SELF.DEUDA_TOTAL, SELF.DEUDA_VENCIDA
		FROM B_PLAN_PAGO PPA
		JOIN B_VENTAS VEN ON VEN.ID = PPA.ID_VENTA
		WHERE VEN.ID = SELF.ID_CLIENTE; 
	END;  
END; 