/*
1.1 CREAR una tabla PEDIDOS con los siguientes campos:
	 ID artículo
	 Cantidad Pedida,
	 Fecha_pedido
*/

CREATE TABLE PEDIDOS (
	ID_ARTICULO NUMBER(8), 
	CANTIDAD_PEDIDA NUMBER(8), 
	FECHA_PEDIDO DATE 
); 

/*
1.2 Desarrollar los triggers que se indican a continuación:
 Un trigger que se disparará DESPUÉS de INSERTAR, MODIFICAR o BORRAR en la tabla
B_DETALLE_VENTAS. El trigger deberá:
	 Actualizar el STOCK_ACTUAL en la tabla B_ARTICULOS (restar del stock
	cuando se inserta una venta, sumar al stock cuando se borra una venta, y modificar el
	stock al actualizar). Puede utilizar el procedimiento
	P_INCREMENTAR_ARTICULO incluido en el paquete PACK_ART desarrollado
	en el ejercicio de paqutes.
	 Actualizar el MONTO_TOTAL en la tabla B_VENTAS (sumar al monto cuando se
inserta una venta, restar del monto cuando se borra, y modificar el monto al
actualizar).
*/

CREATE OR REPLACE TRIGGER T_ACTUALIZAR_STOCK
	AFTER INSERT OR UPDATE OR DELETE ON B_DETALLE_VENTAS
	FOR EACH ROW
DECLARE
BEGIN
	-- Actualizar el STOCK_ACTUAL en la tabla B_ARTICULOS 
	IF INSERTING THEN
		UPDATE B_ARTICULOS 
		SET STOCK_ACTUAL = STOCK_ACTUAL - :NEW.CANTIDAD 
		WHERE ID = :NEW.ID_ARTICULO; 
	
		UPDATE B_VENTAS 
		SET MONTO_TOTAL = MONTO_TOTAL + :NEW.PRECIO * :NEW.CANTIDAD
		WHERE ID = :NEW.ID_VENTA; 
	ELSIF UPDATING THEN 
		UPDATE B_ARTICULOS 
		SET STOCK_ACTUAL = STOCK_ACTUAL - :OLD.CANTIDAD + :NEW.CANTIDAD
		WHERE ID = :NEW.ID_ARTICULO; 
	
		UPDATE B_VENTAS 
		SET MONTO_TOTAL = MONTO_TOTAL - (:OLD.PRECIO * :OLD.CANTIDAD) + (:NEW.PRECIO * :NEW.CANTIDAD)
		WHERE ID = :NEW.ID_VENTA; 
	ELSIF DELETING THEN 
		UPDATE B_ARTICULOS 
		SET STOCK_ACTUAL = STOCK_ACTUAL - :OLD.CANTIDAD 
		WHERE ID = :OLD.ID_ARTICULO; 
	
		UPDATE B_VENTAS 
		SET MONTO_TOTAL = MONTO_TOTAL - :OLD.PRECIO * :OLD.CANTIDAD
		WHERE ID = :OLD.ID_VENTA; 
	END IF; 
END; 

/*
 Un trigger que se disparará ANTES de modificar el campo STOCK_ACTUAL sobre la tabla
B_ARTICULOS. El trigger deberá
 Validar que el nuevo valor de STOCK_ACTUAL no sea <= 0. Si es así el trigger
debe dar el mensaje apropiado y levantar un error.
 Validar que el STOCK_ACTUAL no sea menor que el STOCK_MINIMO. Si es así,
debe insertar un registro en la tabla PEDIDOS. La cantidad pedida debe ser igual al
STOCK_MINIMO + 25%. La fecha del pedido debe ser la fecha del sistema.
*/

CREATE OR REPLACE TRIGGER T_VERIFICAR_STOCK
	BEFORE UPDATE OF STOCK_ACTUAL ON B_ARTICULOS
	FOR EACH ROW
DECLARE
BEGIN 
	IF :NEW.STOCK_ACTUAL <= 0 THEN 
		RAISE_APPLICATION_ERROR (-20001, '(!!!) El stock actual no puede ser negativo'); 
	END IF; 

	IF :NEW.STOCK_ACTUAL < :NEW.STOCK_MINIMO THEN 
		INSERT INTO PEDIDOS VALUES (:NEW.ID, :NEW.STOCK_MINIMO +  :NEW.STOCK_MINIMO * 0.25, SYSDATE); 
	END IF; 
END; 

-- Insertar un stock negativo 
UPDATE B_ARTICULOS SET STOCK_ACTUAL = -1 WHERE ID = 123456; 

-- Dejar el stock por debajo del minimo 
UPDATE B_ARTICULOS SET STOCK_ACTUAL = 1 WHERE ID = 123457; 
SELECT * FROM PEDIDOS; 

/*
 Programe a través de triggers las siguientes reglas de negocio sobre la tabla B_POSICION_ACTUAL:
 Al INSERTAR la nueva posición de un empleado, debe verificar que la categoría que se asigna no
tenga una asignación MENOR a la que tenía anteriormente
 No debe permitir el borrado de un registro.
 */  
CREATE OR REPLACE TRIGGER T_VALIDAR_POS_ACTUAL 
	BEFORE INSERT OR DELETE ON B_POSICION_ACTUAL 
	FOR EACH ROW
DECLARE
	V_NUEVO NUMBER; 
	V_VIEJO NUMBER; 
BEGIN
	IF UPDATING THEN 
		SELECT ASIGNACION INTO V_NUEVO FROM B_CATEGORIAS_SALARIALES WHERE COD_CATEGORIA = :NEW.COD_CATEGORIA;
		SELECT ASIGNACION INTO V_VIEJO FROM B_CATEGORIAS_SALARIALES WHERE COD_CATEGORIA = :OLD.COD_CATEGORIA;

		IF V_NUEVO < V_VIEJO  THEN
			RAISE_APPLICATION_ERROR (-20002, '(!!!) La asignacion actual es menor a la ultima del empleado.'); 
		END IF; 
	END IF; 
	IF DELETING THEN 
			RAISE_APPLICATION_ERROR (-20003, '(!!!) No eliminar asignaciones.'); 
	END IF; 
END; 

/*
4. En la tabla B_CUENTAS debe controlar que una cuenta NO pueda ser padre de otra cuenta si ya es
imputable (IMPUTABLE = ‘S’). Del mismo modo, cuenta NO puede volverse imputable si ya tiene hijos.
Codifique el trigger de manera a evitar que se produzca el error de tabla mutante
*/

-- crear un paquetote para guardar los datos 
	CREATE OR REPLACE PACKAGE PACK_CTAS
	IS
		TYPE T_CTA IS RECORD (
			
			CODIGO_CTA NUMBER, 
			IMPUTABLE VARCHAR2(1), 
			CANT_HIJOS NUMBER
		);
		TYPE T_CUENTAS IS TABLE OF T_CTA INDEX BY BINARY_INTEGER;
		T_CTAS T_CUENTAS;
	END;

-- trigger a nivel de sentencia para guardar los datos 
	CREATE OR REPLACE TRIGGER T_VERIF_CUENTAS 
		BEFORE UPDATE OR INSERT ON B_CUENTAS 
	DECLARE 
		CURSOR C_CUENTAS IS 
			SELECT C.CODIGO_CTA, C.IMPUTABLE, (SELECT COUNT(CU.CODIGO_CTA) FROM B_CUENTAS CU WHERE CU.CTA_SUPERIOR = C.CODIGO_CTA) CANT_HIJOS
			FROM B_CUENTAS C; 
		 v_contador NUMBER;
	BEGIN	
		-- vaciar la variable de paquete 
		PACK_CTAS.T_CTAS.DELETE;
		
		-- guardar datos en el paquete 
		FOR REG IN C_CUENTAS LOOP
			PACK_CTAS.T_CTAS(REG.CODIGO_CTA).CODIGO_CTA := REG.CODIGO_CTA;
			PACK_CTAS.T_CTAS(REG.CODIGO_CTA).IMPUTABLE := REG.IMPUTABLE;
			PACK_CTAS.T_CTAS(REG.CODIGO_CTA).CANT_HIJOS := REG.CANT_HIJOS;
	
		END LOOP;
		
	 	-- imprimir datos del paquete
		 v_contador := PACK_CTAS.T_CTAS.FIRST;
		 WHILE v_contador <= PACK_CTAS.T_CTAS.LAST LOOP
		 	 DBMS_OUTPUT.PUT_LINE('Nombre: ' || PACK_CTAS.T_CTAS(v_contador).CODIGO_CTA); 
		 	 DBMS_OUTPUT.PUT_LINE('Telefono: ' || PACK_CTAS.T_CTAS(v_contador).IMPUTABLE); 
		 	 DBMS_OUTPUT.PUT_LINE('Cedula jefe: ' || PACK_CTAS.T_CTAS(v_contador).CANT_HIJOS); 
		 	 DBMS_OUTPUT.PUT_LINE(' '); 
		 	 v_contador :=  PACK_CTAS.T_CTAS.NEXT(v_contador);
		 END LOOP;
	END; 

-- trigger a nivel de fila 
CREATE OR REPLACE TRIGGER T_VALIDAR_CUENTAS 
	AFTER UPDATE OR INSERT ON B_CUENTAS 
	FOR EACH ROW
BEGIN
	
	IF :NEW.IMPUTABLE = 'S' AND PACK_CTAS.T_CTAS(:NEW.CODIGO_CTA).CANT_HIJOS != 0 THEN 
		RAISE_APPLICATION_ERROR (-20001, '(!!!) No puede asignar el valor imputable a una cuenta con hijos. '); 
	END IF; 

	IF PACK_CTAS.T_CTAS(:NEW.CTA_SUPERIOR).IMPUTABLE = 'S' THEN 
		RAISE_APPLICATION_ERROR (-20002, '(!!!) No puede asignar como cuenta superior a una cuenta imputable.  '); 
	END IF; 
	
END; 
