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
