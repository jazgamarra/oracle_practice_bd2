/*
 * 
 * Base de datos II 
 * Primer examen final 
 * 
 * Jazmin Maria del Lujan Gamarra Benitez 
 * jazgamarra@fpuna.edu.py 
 * 
 */

-------------------------------------------------------------------------------------------
-- TEMA 1 
-------------------------------------------------------------------------------------------

-- Crear el objeto O_PAGO 
CREATE OR REPLACE TYPE O_PAGO AS OBJECT (
	ID_OPERACION NUMBER(12), 
	SALDO_A_PAGAR NUMBER(12), 
	IMPORTE_PAGO NUMBER(12)
); 

-- Crear tipo tabla 
CREATE TYPE T_PAGO AS TABLE OF O_PAGO; 

-- Alterar tabla d_pago_operacion para agregar la columa  
ALTER TABLE D_PAGO_OPERACION ADD DETALLE_PAGOS T_PAGO NESTED TABLE DETALLE_PAGOS STORE AS NT_PAGO; 


-------------------------------------------------------------------------------------------
-- TEMA 2 
-------------------------------------------------------------------------------------------

-- Crear la vista materializada 
CREATE MATERIALIZED VIEW V_COMPRAS
	REFRESH COMPLETE
	NEXT TRUNC(SYSDATE) + 1 + INTERVAL '5' HOUR -- al dia siguiente a las 5 am 
	WITH PRIMARY KEY
AS 
	SELECT MO.ID_OPERACION, MO.ID_PERSONA "ID_PROVEEDOR", P.RUC "RUC_PROVEEDOR", P.DENOMINACION "RAZON_SOCIAL", 
		MO.NRO_COMPROBANTE "NRO_FACTURA", FECHA_INSERT "FECHA_FACTURA", SUM(DO.IMPORTE_OPERACION-DO.IMPORTE_DESCUENTO+DO.IMPORTE_RECARGO) "MONTO_FACTURA", 
		NVL((SELECT SUM(IMPORTE_PAGO) FROM D_PAGO_OPERACION PO WHERE PO.ID_REGISTRO = MO.ID_OPERACION), 0) "MONTO_PAGADO", 
		SUM(DO.IMPORTE_OPERACION-DO.IMPORTE_DESCUENTO+DO.IMPORTE_RECARGO) - NVL((SELECT SUM(IMPORTE_PAGO) 
		FROM D_PAGO_OPERACION PO WHERE PO.ID_REGISTRO = MO.ID_OPERACION), 0) "MONTO_A_PAGAR "
	FROM D_MOVIMIENTO_OPERACIONES MO
	JOIN D_PERSONAS P ON P.ID_PERSONA = MO.ID_PERSONA 
	JOIN D_DETALLE_OPERACIONES DO ON DO.ID_OPERACION = MO.ID_OPERACION 
	WHERE MO.COD_OPERACION = (SELECT COD_OPERACION FROM D_OPERACIONES WHERE DESC_OPERACION LIKE 'COMPRA')
	AND MO.ESTADO = 'A' 
	GROUP BY MO.ID_OPERACION, MO.ID_PERSONA, P.RUC, P.DENOMINACION, MO.NRO_COMPROBANTE, FECHA_INSERT;

-- Consultar la vista 
SELECT * FROM V_COMPRAS;


-------------------------------------------------------------------------------------------
-- TEMA 3
-------------------------------------------------------------------------------------------

-- Crear la cabecera del paquete 
CREATE OR REPLACE PACKAGE PCK_PAGOS AS 
	FUNCTION F_COMPRAS_PENDIENTES RETURN T_PAGO; 
	PROCEDURE P_PAGAR (MONTO_PAGO IN NUMBER, V_TABLA IN OUT T_PAGO); 
	PROCEDURE P_CONSULTAR(P_CRITERIO VARCHAR2, P_TIPO_OP VARCHAR2 ); 
END; 

-- Crear el cuerpo del paquete 
CREATE OR REPLACE PACKAGE BODY PCK_PAGOS IS  
	-- Funcion compras pendientes 
	FUNCTION F_COMPRAS_PENDIENTES RETURN T_PAGO IS 
		CURSOR C_COMPRAS IS SELECT ID_OPERACION, MONTO_A_PAGAR, MONTO_PAGADO FROM V_COMPRAS; 
		V_TABLA T_PAGO := T_PAGO(); 
		V_CONTADOR NUMBER := 0; 
	BEGIN 
		-- Cargar datos en la tabla 
		FOR REG IN C_COMPRAS LOOP
			V_CONTADOR := V_CONTADOR+1; 
			V_TABLA.EXTEND(); 
			V_TABLA(V_CONTADOR) := O_PAGO(REG.ID_OPERACION, REG.MONTO_A_PAGAR, REG.MONTO_PAGADO); 
		END LOOP; 
	
		-- Mostrar los datos cargados en consola 
		v_contador := V_TABLA.FIRST;
		WHILE v_contador <= V_TABLA.LAST LOOP
		 	DBMS_OUTPUT.PUT_LINE('Id: ' || V_TABLA(v_contador).ID_OPERACION); 
		 	DBMS_OUTPUT.PUT_LINE('Saldo: ' || V_TABLA(v_contador).SALDO_A_PAGAR); 
		 	DBMS_OUTPUT.PUT_LINE('Pagado: ' || V_TABLA(v_contador).IMPORTE_PAGO); 
		 	DBMS_OUTPUT.PUT_LINE(' '); 
		 	v_contador := V_TABLA.NEXT(v_contador);
		END LOOP;
		
		RETURN V_TABLA; 
	END; 

	-- Procedimiento pagar 
	PROCEDURE P_PAGAR (MONTO_PAGO IN NUMBER, V_TABLA IN OUT T_PAGO) IS 
		V_CONTADOR NUMBER; 
		V_MONTO_TEMP NUMBER := MONTO_PAGO; 
	BEGIN
		-- Recorrer la tabla recibida por parametro 
		v_contador := V_TABLA.FIRST;
		WHILE v_contador <= V_TABLA.LAST LOOP
			
			-- Se asignan los valores 
			IF MONTO_PAGO >= V_TABLA(v_contador).SALDO_A_PAGAR THEN 
				V_TABLA(v_contador).IMPORTE_PAGO := V_TABLA(v_contador).SALDO_A_PAGAR; 
				V_MONTO_TEMP := V_MONTO_TEMP - V_TABLA(v_contador).SALDO_A_PAGAR; 
			ELSIF MONTO_PAGO < V_TABLA(v_contador).SALDO_A_PAGAR THEN 
				V_TABLA(v_contador).IMPORTE_PAGO := MONTO_PAGO; 
				V_MONTO_TEMP := V_MONTO_TEMP - MONTO_PAGO; 
			END IF; 
			
			-- Se verifica si se llego a cero 
			IF V_MONTO_TEMP = 0 THEN
				V_TABLA.delete(v_contador, v_tabla.last); 
				EXIT WHEN V_MONTO_TEMP = 0; 
			END IF; 
		
		 	v_contador := V_TABLA.NEXT(v_contador);
		END LOOP;
	END; 

	-- Consultar 
	PROCEDURE P_CONSULTAR(P_CRITERIO VARCHAR2, P_TIPO_OP VARCHAR2) IS 
		V_SQL_CRITERIO VARCHAR2(30); 
		V_SQL_TIPO_OP VARCHAR2(30); 
		V_SQL VARCHAR(800); 
	BEGIN 
		-- Criterio 
		IF P_CRITERIO = 'C' THEN
			V_SQL_CRITERIO := 'P.DENOMINACION'; 
		ELSIF P_CRITERIO = 'U' THEN 
			V_SQL_CRITERIO := 'U.NOMBRE_USUARIO';
		ELSE 
			RAISE_APPLICATION_ERROR (-20001, '(!!!)  El parametro enviado como criterio debe ser "C" o "U" ');  
		END IF;
	
		-- Tipo de operacion 
		IF P_TIPO_OP = 'V' THEN
			V_SQL_TIPO_OP := '1'; 
		ELSIF P_TIPO_OP = 'C' THEN 
			V_SQL_TIPO_OP := '2';
		ELSE 
			RAISE_APPLICATION_ERROR (-20002, '(!!!)  El parametro enviado como tipo de operacion debe ser "C" o "V" ');  
		END IF;
	
		-- Generar el sql 
		V_SQL := '
			SELECT MO.ID_OPERACION,' || V_SQL_CRITERIO || ', MO.NRO_COMPROBANTE, MO.FECHA_OPERACION, 
			SUM(DO.IMPORTE_OPERACION - DO.IMPORTE_DESCUENTO + DO.IMPORTE_RECARGO) MONTO
			FROM D_MOVIMIENTO_OPERACIONES MO 
			JOIN D_PERSONAS P ON P.ID_PERSONA  = MO.ID_PERSONA 
			JOIN D_USUARIOS U ON U.ID_USUARIO = MO.ID_USUARIO
			JOIN D_DETALLE_OPERACIONES DO ON DO.ID_OPERACION  = MO.ID_OPERACION
			WHERE MO.COD_OPERACION = ' || V_SQL_TIPO_OP || 
			'GROUP BY MO.ID_OPERACION, P.DENOMINACION, MO.NRO_COMPROBANTE, MO.FECHA_OPERACION, U.NOMBRE_USUARIO';
	
		-- Ejecutar el codigo
		EXECUTE IMMEDIATE V_SQL;
	
		-- Mostrar el codigo generado
		DBMS_OUTPUT.PUT_LINE('Codigo generado:'||V_SQL);

	END; 
END; 


-------------------------------------------------------------------------------------------
-- TEMA 3
-------------------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER T_INS_PAGO_OP 
	BEFORE INSERT ON D_PAGO_OPERACION 
	FOR EACH ROW 
DECLARE 
	V_CHEQUERA_ACTIVA NUMBER; 
	V_ULTIMO NUMBER; 
	V_HASTA NUMBER; 
	V_SERIE VARCHAR2(2); 
	v_contador NUMBER; 
	V_TEMP_OP NUMBER; 
	V_SUM_IMPORTE_PAGO NUMBER := 0; 
BEGIN
	-- Se verifican los tipos de pago 
	IF :NEW.COD_FORMA_PAGO IN (10, 11) THEN 
		IF :NEW.COD_FORMA_PAGO = 11 THEN
			SELECT NVL(NRO_CHEQUERA, -1), ULTIMO_NRO + 1, NRO_HASTA, SERIE 
			INTO V_CHEQUERA_ACTIVA, V_ULTIMO, V_HASTA, V_SERIE 
			FROM D_CHEQUES WHERE ACTIVO = 'S'; -- puedo hacer eso porque se supone que hay solo una activa 
			
			-- Si no se encuentra una chequera activa 
			IF V_CHEQUERA_ACTIVA = -1 THEN 
				RAISE_APPLICATION_ERROR (-20003, '(!!!) No existe chequera activa ');  
			END IF; 
			
			-- Se verifica si se sobrepasa la cant de la chequera 
			IF V_ULTIMO > V_HASTA THEN 
				RAISE_APPLICATION_ERROR (-20004, '(!!!)  Se sobrepasa el limite de la chequera activa');  
			ELSE 
				-- Se incrementa en uno la chequera 
				UPDATE D_CHEQUES SET ULTIMO_NRO = V_ULTIMO WHERE NRO_CHEQUERA = V_CHEQUERA_ACTIVA; 
			END IF; 
		
			-- Se agregan valores a la insercion actual 
			:NEW.NRO_CHEQUERA := V_CHEQUERA_ACTIVA; 
			:NEW.NRO_CHEQUE := CONCAT(V_SERIE, V_ULTIMO); 
		END IF;
	
		-- Compras pendientes 
		:NEW.DETALLE_PAGOS := PCK_PAGOS.F_COMPRAS_PENDIENTES(); 
	
		-- Pagar 
		PCK_PAGOS.P_PAGAR(:NEW.IMPORTE_PAGO, :NEW.DETALLE_PAGOS); 
	
	ELSE 
	
		-- Verificar que haya elementos en detalle_pagos 
		IF :NEW.DETALLE_PAGOS.COUNT = 0 THEN 
			RAISE_APPLICATION_ERROR (-20007, '(!!!) Debe indicar las operaciones que se pagan. '); 
		END IF; 
	
		-- Recorrer detalle_pagos 
		v_contador := :NEW.DETALLE_PAGOS.FIRST;
		WHILE v_contador <= :NEW.DETALLE_PAGOS.LAST LOOP
			
			-- Verificar que todas las operaciones de venta sean 
			SELECT COD_OPERACION INTO V_TEMP_OP FROM D_MOVIMIENTO_OPERACIONES WHERE ID_OPERACION = :NEW.DETALLE_PAGOS.(v_contador).ID_OPERACION; 
		 	IF V_TEMP_OP <> 1 THEN
				RAISE_APPLICATION_ERROR (-20005, '(!!!)  Solo corresponde pagar ventas. ');  
		 	END IF; 
		 	
		 	-- Sumar lo de importe pago 
		 	V_SUM_IMPORTE_PAGO := V_SUM_IMPORTE_PAGO + :NEW.DETALLE_PAGOS.(v_contador).IMPORTE_PAGO; 
		 	
		 	v_contador := :NEW.DETALLE_PAGOS.NEXT(v_contador);
		END LOOP;
		
		-- Verificar si coinciden las sumas 
		IF V_SUM_IMPORTE_PAGO <> :NEW.IMPORTE_PAGO THEN 
			RAISE_APPLICATION_ERROR (-20006, '(!!!) Importe de pago debe coincidir con la suma del detalle. '); 
		END IF; 
	END IF;
END;