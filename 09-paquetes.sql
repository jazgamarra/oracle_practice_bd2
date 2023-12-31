/*
1. Crear el package PACK_PER cuyas especificaciones tendrán lo siguiente:
- La definición de un tipo registro con los campos MONTO_VENTAS , MONTO_COMISION
- La definición de un tipo tabla asociativa cuyos componentes son del tipo de registro creado,
- La definición de una variable de tipo boolean denominada V_CALCULA_BONIF inicializado a TRUE.

- La función F_APELLIDO_NOMBRE que recibe como parámetro la cédula del empleado y devuelve un
varchar2 concatenando ‘apellido, nombre’. Prever que la función pueda ser empleada en cualquier
sentencia SELECT.
- La función F_CALCULAR_BONIFICACIÓN que recibirá como parámetros el año y mes, calculará el
monto de ventas y la bonificación correspondientes al año y mes introducidos por parámetro, de todos los
empleados, las cargará en la tabla asociativa creada, indexando por cédula del empleado, y devolverá
dicha tabla..
- Sobrecargue la función F_CALCULAR_BONIFICACIÓN para que reciba solamente la cédula de un
empleado, y devuelva la bonificación por venta correspondiente a ese empleado en el mes y año del
sistema.
*/

-- Crear la cabecera  
CREATE OR REPLACE PACKAGE PACK_PER AS 
	TYPE R_MONTOS IS RECORD (MONTO_VENTAS NUMBER, MONTO_COMISION NUMBER);
	TYPE T_MONTOS IS TABLE OF R_MONTOS INDEX BY BINARY_INTEGER; 
	V_CALCULA_BONIF BOOLEAN := TRUE; 
	FUNCTION F_APELLIDO_NOMBRE (P_CEDULA NUMBER) RETURN VARCHAR2; 
	FUNCTION F_CALCULAR_BONIFICACION(P_MES NUMBER, P_ANHO NUMBER) RETURN T_MONTOS; 
	FUNCTION F_CALCULAR_BONIFICACION(P_CEDULA NUMBER) RETURN T_MONTOS; 
END; 

-- Cuerpo del paquete 
CREATE OR REPLACE PACKAGE BODY PACK_PER IS  
	-- Retornar nombre y apellido 
	FUNCTION F_APELLIDO_NOMBRE (P_CEDULA NUMBER) RETURN VARCHAR2 IS 
		V_NOMBRE_APELLIDO VARCHAR2(30); 
	BEGIN 
		SELECT APELLIDO || ', ' || NOMBRE INTO V_NOMBRE_APELLIDO FROM B_EMPLEADOS WHERE CEDULA = P_CEDULA; 
		RETURN V_NOMBRE_APELLIDO; 
	END; 

	-- Retornar montos dependiendo de la fecha y anho 
	FUNCTION F_CALCULAR_BONIFICACION(P_MES NUMBER, P_ANHO NUMBER) RETURN T_MONTOS IS
		V_TEMP T_MONTOS; 
		CURSOR C_MONTOS  IS 
			SELECT VEN.CEDULA_VENDEDOR, SUM(DVE.PRECIO * DVE.CANTIDAD * ART.PORC_COMISION) COMISION, SUM(DVE.PRECIO * DVE.CANTIDAD) VENTAS 
			FROM B_VENTAS VEN 
			JOIN B_DETALLE_VENTAS DVE ON DVE.ID_VENTA = VEN.ID 
			JOIN B_ARTICULOS ART ON ART.ID = DVE.ID_ARTICULO
			WHERE EXTRACT(YEAR FROM VEN.FECHA) = 2018 AND EXTRACT(MONTH FROM VEN.FECHA) = 8
			GROUP BY VEN.CEDULA_VENDEDOR; 
	BEGIN 
		FOR C_MONTO IN C_MONTOS LOOP   
			V_TEMP(C_MONTO.CEDULA_VENDEDOR).MONTO_VENTAS := C_MONTO.VENTAS; 
			V_TEMP(C_MONTO.CEDULA_VENDEDOR).MONTO_COMISION := C_MONTO.COMISION; 
		END LOOP;
		RETURN V_TEMP; 
	END; 
	
	-- Retornar montos dependiendo de la cedula
	FUNCTION F_CALCULAR_BONIFICACION(P_CEDULA NUMBER) RETURN T_MONTOS IS
		V_TEMP T_MONTOS; 
		CURSOR C_MONTOS  IS 
			SELECT VEN.CEDULA_VENDEDOR, SUM(DVE.PRECIO * DVE.CANTIDAD * ART.PORC_COMISION) COMISION, SUM(DVE.PRECIO * DVE.CANTIDAD) VENTAS 
			FROM B_VENTAS VEN 
			JOIN B_DETALLE_VENTAS DVE ON DVE.ID_VENTA = VEN.ID 
			JOIN B_ARTICULOS ART ON ART.ID = DVE.ID_ARTICULO
			WHERE VEN.CEDULA_VENDEDOR = P_CEDULA 
			GROUP BY VEN.CEDULA_VENDEDOR;
	BEGIN 
		FOR C_MONTO IN C_MONTOS LOOP   
			V_TEMP(C_MONTO.CEDULA_VENDEDOR).MONTO_VENTAS := C_MONTO.VENTAS; 
			V_TEMP(C_MONTO.CEDULA_VENDEDOR).MONTO_COMISION := C_MONTO.COMISION; 
		END LOOP;
		RETURN V_TEMP; 
	END; 
END; 

/* 
 Pruebe en un SELECT la función del paquete: Seleccione cédula, nombre del empleado, nombre del
jefe, utilizando la función de paquete F_APELLIDO_NOMBRE.
 */
SELECT CEDULA, PACK_PER.F_APELLIDO_NOMBRE(CEDULA) NOMBRE_EMPEADO,
PACK_PER.F_APELLIDO_NOMBRE(CEDULA_JEFE) NOMBRE_JEFE
FROM B_EMPLEADOS;  



-- C.A (?)

-- Calcular la bonficacion teniendo la fecha 
SELECT VEN.CEDULA_VENDEDOR, SUM(DVE.PRECIO * DVE.CANTIDAD * ART.PORC_COMISION) COMISION, SUM(DVE.PRECIO * DVE.CANTIDAD) VENTAS 
FROM B_VENTAS VEN 
JOIN B_DETALLE_VENTAS DVE ON DVE.ID_VENTA = VEN.ID 
JOIN B_ARTICULOS ART ON ART.ID = DVE.ID_ARTICULO
WHERE EXTRACT(YEAR FROM VEN.FECHA) = 2018 AND EXTRACT(MONTH FROM VEN.FECHA) = 8
GROUP BY VEN.CEDULA_VENDEDOR; 

-- Calcular la bonficacion teniendo la cedula
SELECT VEN.CEDULA_VENDEDOR, SUM(DVE.PRECIO * DVE.CANTIDAD * ART.PORC_COMISION) COMISION, SUM(DVE.PRECIO * DVE.CANTIDAD) VENTAS 
FROM B_VENTAS VEN 
JOIN B_DETALLE_VENTAS DVE ON DVE.ID_VENTA = VEN.ID 
JOIN B_ARTICULOS ART ON ART.ID = DVE.ID_ARTICULO
GROUP BY VEN.CEDULA_VENDEDOR;