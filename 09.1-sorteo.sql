/*
 * Ejercicio 4 del ejercitario de paquetes. 
 */

-- crear una secuencia para el id de los cupones 
CREATE SEQUENCE p_id_cupones
INCREMENT BY 1
START WITH 1
MAXVALUE 9999999
NOCACHE NOCYCLE;

-- CABECERA DEL PAQUETE 
CREATE OR REPLACE PACKAGE PCK_SORTEO AS 
	FUNCTION F_GENERAR_CUPONES RETURN NUMBER; 
	FUNCTION F_CONSULTAR_CUPONES (P_CEDULA number) RETURN NUMBER; 
	FUNCTION F_SORTEAR (P_PREMIO VARCHAR2)  RETURN VARCHAR2; 
END; 


-- CUERPO DEL PAQUETE 
CREATE OR REPLACE PACKAGE BODY PCK_SORTEO IS 
	
	/*
	Este botón llama a la función F_GENERAR_CUPONES que recupera todas las ventas al contado efectuadas
	en el año 2011 y por las boletas con montos >= 100.000 gs genera cupones. Es decir inserta en la tabla
	B_CUPONES un registro por cada 100.000 gs.
	Ejemplo: Si el importe total de la venta con ID 2 es de 500.000gs entonces se insertan 5 registros en la tabla
	mencionada.
	Luego de haber hecho todas las inserciones retorna la cantidad de cupones generados.
	*/

	FUNCTION F_GENERAR_CUPONES RETURN NUMBER IS 
		CURSOR C_VENTAS_CUPONES IS 
			SELECT ID ID_VENTA, ID_CLIENTE, MONTO_TOTAL, FLOOR(MONTO_TOTAL/100000) CANT_CUPONES
			FROM b_ventas VEN
			WHERE VEN.TIPO_VENTA = 'CO' AND MONTO_TOTAL > 100000
			GROUP BY ID, MONTO_TOTAL, ID_CLIENTE; 
		V_CUPONES_GENERADOS NUMBER := 0; 
	BEGIN
		FOR VEN IN C_VENTAS_CUPONES LOOP
			FOR i IN 1..VEN.CANT_CUPONES LOOP 
				INSERT INTO B_CUPONES VALUES (p_id_cupones.nextval, VEN.ID_VENTA, ven.ID_CLIENTE); 
			END LOOP;
			V_CUPONES_GENERADOS := V_CUPONES_GENERADOS + VEN.CANT_CUPONES;
		END LOOP;
		RETURN V_CUPONES_GENERADOS; 
	END;

	/*
	Al pulsar este botón se invoca a la función F_CONSULTAR_CUPONES, la misma recibe como parámetro la
	cédula de un cliente y retorna la cantidad de cupones que se le han generado. En caso de que el cliente no
	existe emite un mensaje de error.
	*/ 

	FUNCTION F_CONSULTAR_CUPONES (P_CEDULA number) RETURN NUMBER IS 
		V_ID_CLIENTE NUMBER; 
		V_CANTIDAD_CUPONES NUMBER; 
	BEGIN 
		BEGIN 
			SELECT ID INTO V_ID_CLIENTE FROM B_PERSONAS WHERE CEDULA = P_CEDULA; 
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('No se encontro un cliente con cedula nro. ' || P_CEDULA);
				RETURN 0; 
		END; 
			
		SELECT count(id_cupon) INTO v_cantidad_cupones FROM b_cupones WHERE id_cliente = V_ID_CLIENTE; 
		RETURN V_CANTIDAD_CUPONES; 
	END; 

	/*
	Al presionar el botón se llama a la función F_SORTEAR que recibe como
	parámetro el nombre del premio a sortear; luego selecciona aleatoriamente (*) un número de cupón de la tabla B_CUPONES.
	Si el cupón es de un cliente que aún no fue adjudicado con algún premio, inserta un registro en la tabla
	B_CUPONES_GANADORES, caso contrario vuelve a seleccionar otro número de cupón.
	Por último, debe retornar el nombre y apellido del cliente ganador.
	*/
	

	FUNCTION F_SORTEAR (P_PREMIO VARCHAR2) RETURN VARCHAR2 IS 
		CUPON_SORTEADO NUMBER; 
		ID_GANADOR NUMBER; 
		NOMBRE_GANADOR VARCHAR(100); 
		CANT_VECES_GANADOR NUMBER := 1; 
	BEGIN
		-- encontrar un ganador 
		WHILE CANT_VECES_GANADOR <> 0 LOOP
			-- sortear el cupon
			CUPON_SORTEADO := round(DBMS_RANDOM.VALUE(0, p_id_cupones.currval)); 
			
			-- seleccionar el ganador 
			SELECT ID_CLIENTE
			INTO ID_GANADOR 
			FROM B_CUPONES 
			WHERE ID_CUPON = CUPON_SORTEADO; 
	
			-- verificar si el ganador ya gano alguna vez 
			SELECT COUNT(*) INTO CANT_VECES_GANADOR
			FROM B_CUPONES 
			JOIN B_CUPONES_GANADORES ON ID_CUPON_GAN = ID_CUPON
			WHERE ID_CLIENTE = ID_GANADOR; 
		END LOOP; 
	
		-- insertar en la tabla de cupones ganadores 
		INSERT INTO B_CUPONES_GANADORES VALUES (CUPON_SORTEADO, SYSDATE, P_PREMIO); 
	
		-- ver nombre del ganador 
		SELECT  NOMBRE || ' ' || APELLIDO INTO NOMBRE_GANADOR FROM B_PERSONAS WHERE ID=ID_GANADOR; 	
	
		RETURN NOMBRE_GANADOR; 
	END; 
END; 


/* Pruebas */
DECLARE
  V_CUP_GENERADOS NUMBER;
BEGIN
  V_CUP_GENERADOS := PCK_SORTEO.F_GENERAR_CUPONES;
  DBMS_OUTPUT.PUT_LINE ('Cupones generados: '||V_CUP_GENERADOS);
END;


DECLARE
  V_CANTIDAD NUMBER;
BEGIN
  V_CANTIDAD := PCK_SORTEO.F_CONSULTAR_CUPONES(1207876);
  DBMS_OUTPUT.PUT_LINE ('Cantidad cupones: '||V_CANTIDAD);
END;


DECLARE
  VNOM_CLIENTE VARCHAR2(300);
BEGIN
  VNOM_CLIENTE := PCK_SORTEO.F_SORTEAR('TV TOKYO 50"');
  DBMS_OUTPUT.PUT_LINE ('Cliente ganador: '||VNOM_CLIENTE);
END;


/* Revisar las tablas */
SELECT * FROM B_CUPONES;
SELECT * FROM B_CUPONES_GANADORES;









/* Sintaxis de creacion de esas tablas -- la prof. nos dio esto:  */
CREATE TABLE B_CUPONES
(
  ID_CUPON   NUMBER(8) NOT NULL,
  ID_VENTA   NUMBER(8) NOT NULL,
  ID_CLIENTE NUMBER(8) NOT NULL
);


ALTER TABLE B_CUPONES
ADD CONSTRAINT PK_ID_CUPON PRIMARY KEY (ID_CUPON);
ALTER TABLE B_CUPONES
ADD CONSTRAINT FK_ID_CLI_CP FOREIGN KEY (ID_CLIENTE) REFERENCES B_PERSONAS (ID);
ALTER TABLE B_CUPONES
ADD CONSTRAINT FK_ID_VTA_CP FOREIGN KEY (ID_VENTA)REFERENCES B_VENTAS (ID);


CREATE TABLE B_CUPONES_GANADORES
(
  ID_CUPON_GAN      NUMBER(8) NOT NULL,
  FECHA_SORTEO      DATE NOT NULL,
  PREMIO_ADJUDICADO VARCHAR2(100) NOT NULL
);

ALTER TABLE B_CUPONES_GANADORES
ADD CONSTRAINT PK_ID_CUP_GAN PRIMARY KEY (ID_CUPON_GAN);

ALTER TABLE B_CUPONES_GANADORES
ADD CONSTRAINT FK_ID_CUP_GAN FOREIGN KEY (ID_CUPON_GAN)REFERENCES B_CUPONES (ID_CUPON);
