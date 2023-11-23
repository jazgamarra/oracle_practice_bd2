
-- Cabecera del paquete 
CREATE OR REPLACE PACKAGE t_detalle AS 
	TYPE R_DETALLE IS RECORD (ID_PRODUCTO NUMBER, CANTIDAD NUMBER); 
	TYPE T_DETALLE IS TABLE OF R_DETALLE INDEX BY BINARY_INTEGER; 
	PROCEDURE P_INSERTAR_MOVIMIENTO(cod_sucursal NUMBER, fecha_operacion DATE, cod_operacion NUMBER, id_persona NUMBER, 
		id_usuario VARCHAR2(10),  descripcion_operacion VARCHAR2(30),  nro_caja NUMBER); 
	FUNCTION F_ACTUALIZAR_STOCK (id_producto NUMBER, cod_sucursal NUMBER, cantidad NUMBER, uso_stock NUMBER) RETURN BOOLEAN; 
	FUNCTION F_VER_DETALLE(ID_OPERACION NUMBER) RETURN T_DETALLE; 
END; 

-- Cuerpo del paquete
CREATE OR REPLACE PACKAGE BODY t_detalle IS  

	PROCEDURE P_INSERTAR_MOVIMIENTO(P_cod_sucursal NUMBER, fecha_operacion DATE, p_cod_operacion NUMBER, 
		id_persona NUMBER, id_usuario VARCHAR2,  descripcion_operacion VARCHAR2,  p_nro_caja NUMBER)  
	IS 
		V_USO_CAJERO NUMBER;
		V_CAJA_VALIDA NUMBER; 
		V_timbrado NUMBER; 
		V_ACTUAL NUMBER; 
		V_NRO_VALIDO NUMBER; 
		V_NRO_CAJA NUMBER;
	BEGIN 	
		-- Validar fechas adelantadas 
		IF EXTRACT(YEAR FROM FECHA_OPERACION) <> 2023 AND FECHA_OPERACION > SYSDATE THEN 
			RAISE_APPLICATION_ERROR (-20001, '(!!!) No se admiten fechas adelantadas. ');  
		END IF; 
	
		-- Validar si es de uso cajero 
		SELECT O.USO_CAJERO INTO V_USO_CAJERO FROM D_OPERACIONES O WHERE O.COD_OPERACION = P_COD_OPERACION; 
	
		IF V_USO_CAJERO = 1 THEN
			-- Validar si es caja nula 
			IF P_NRO_CAJA IS null THEN 
				RAISE_APPLICATION_ERROR (-20002, '(!!!) La caja no puede ser nula si es de uso cajero. ');  
			END IF; 
		
			-- Validar si la caja existe 
			SELECT CASE WHEN M.NRO_CAJA IN (SELECT C.NRO_CAJA FROM D_CAJAS C) THEN 1 ELSE 0 END 
			INTO V_CAJA_VALIDA
			FROM D_MOVIMIENTO_OPERACIONES M
			WHERE M.NRO_CAJA = P_NRO_CAJA; 
			IF V_CAJA_VALIDA = 0 THEN 
				RAISE_APPLICATION_ERROR (-20003, '(!!!) La caja no es valida. ');  
			END IF; 
		END IF; 
	
		-- Si el nro de caja es nulo se asigna 1 
		IF P_NRO_CAJA IS NULL THEN 
			V_NRO_CAJA := 1; 
		ELSE 
			V_NRO_CAJA := P_NRO_CAJA; 
		END IF;  
	
		SELECT nvl(nro_timbrado, 0), NUMERO_ACTUAL, 
		CASE WHEN T.NUMERO_ACTUAL >= T.DESDE_NUMERO AND T.NUMERO_ACTUAL <= T.HASTA_NUMERO 
		THEN 1 ELSE 0 END 
		INTO V_TIMBRADO, V_ACTUAL, V_NRO_VALIDO 
		FROM D_TIMBRADO t
		WHERE T.COD_SUCURSAL = P_COD_SUCURSAL 
		AND T.NRO_CAJA = V_NRO_CAJA
		AND fecha_operacion >= T.FECHA_DESDE_TIMBRADO 
		AND fecha_operacion <= T.FECHA_HASTA_TIMBRADO; 
	
		-- Lanzar error si el timbrado no es valido 
		IF V_TIMBRADO = 0 THEN 
			RAISE_APPLICATION_ERROR (-20004, '(!!!)  No se encuentran timbrados vigentes. ');  
		END IF; 
	
		-- Si el numero actual no es valido 
		IF v_nro_valido = 0 THEN
			RAISE_APPLICATION_ERROR (-20005, '(!!!)  El numero_actual no es valido . ');  
		END IF; 
			
		-- Actualizar valor del numero actual 
		UPDATE D_TIMBRADO SET NUMERO_ACTUAL = NUMERO_ACTUAL + CASE WHEN NUMERO_ACTUAL <= HASTA_NUMERO  THEN 1 ELSE 0 END WHERE NRO_TIMBRADO = V_TIMBRADO; 
	
		-- Insertar en la tabla
	END; 
END; 
