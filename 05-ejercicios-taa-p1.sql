/*
 * Cree la vista materializada V_LIQUIDACION que contenga los siguientes campos a partir de la tabla B_EMPLEADOS
 * La vista se deberá crearse este fin de mes y refrescarse cada fin de mes a la medianoche. 
 */

-- ver bonificacion de cada uno 
SELECT VEN.CEDULA_VENDEDOR, SUM(DEV.PRECIO*DEV.CANTIDAD*ART.PORC_COMISION)
FROM B_ARTICULOS ART 
JOIN B_DETALLE_VENTAS DEV ON DEV.ID_ARTICULO = ART.ID 
JOIN B_VENTAS VEN ON VEN.ID = DEV.ID_VENTA 
GROUP BY VEN.CEDULA_VENDEDOR

-- crear la vista 
CREATE MATERIALIZED VIEW V_LIQUIDACION 
	BUILD IMMEDIATE 
	REFRESH COMPLETE START WITH LAST_DAY(sysdate) /* TRUNC(LAST_DAY(sysdate))*/
	NEXT TRUNC(SYSDATE+30, 'MONTH')-1 /* TRUNC(ADD_MONTHS(LAST_DAY(sysdate), 1)) */
AS 
WITH BONIFICACIONES AS (SELECT VEN.CEDULA_VENDEDOR, SUM(DEV.PRECIO*DEV.CANTIDAD*ART.PORC_COMISION) BONIF
	FROM B_ARTICULOS ART 
	JOIN B_DETALLE_VENTAS DEV ON DEV.ID_ARTICULO = ART.ID 
	JOIN B_VENTAS VEN ON VEN.ID = DEV.ID_VENTA 
	GROUP BY VEN.CEDULA_VENDEDOR
)
SELECT EMP.CEDULA, CAT.ASIGNACION, (CAT.ASIGNACION * 0.09) IPS, BON.BONIF
	FROM B_EMPLEADOS EMP 
	JOIN B_POSICION_ACTUAL POS ON POS.CEDULA = EMP.CEDULA 
	JOIN B_CATEGORIAS_SALARIALES CAT ON CAT.COD_CATEGORIA = POS.COD_CATEGORIA 
	JOIN BONIFICACIONES BON ON BON.CEDULA_VENDEDOR = EMP.CEDULA; 
	
--  Cree el sinónimo público V_LIQUIDACIÓN para la vista creada (2P)
CREATE PUBLIC SYNONYM V_LIQUIDACIÓN FOR V_LIQUIDACION; 
	
--  Cree el ROL R_LIQ (2P)
alter session set "_ORACLE_SCRIPT"=true;
CREATE ROLE R_LIQ; 
	
-- Conceda al rol R_LIQ los siguientes accesos: 
-- Consulta sobre la vista creada, e INSERT, UPDATE sobre las vistas B_PLANILLA y B_LIQUIDACION
GRANT SELECT ON V_LIQUIDACION TO R_LIQ; 
GRANT INSERT, UPDATE ON B_PLANILLA TO R_LIQ; 
GRANT INSERT, UPDATE ON B_LIQUIDACION TO R_LIQ; 

	
	
	



-- Exception handling 
 */
DECLARE 
	v_id_producto EX_PRODUCCION.ID_PRODUCTO%TYPE := &v_id_producto;
	v_cantidad_producir EX_PRODUCCION.CANTIDAD_A_PRODUCIR%TYPE := &v_cantidad_producir;
	v_fecha_orden EX_PRODUCCION.FECHA_ORDEN%TYPE := '&v_fecha_orden';
	v_tipo_articulo B_ARTICULOS.TIPO_ARTICULO%TYPE; 
	v_id_insumo EX_INSUMOS.ID_INSUMO%TYPE; 
	v_id_produccion EX_PRODUCCION.ID_PRODUCCION%TYPE;
	ex_no_prod EXCEPTION; 
	no_data EXCEPTION; 
BEGIN
	BEGIN 
		SELECT ID INTO v_id_producto FROM B_ARTICULOS WHERE ID = v_id_producto; 
	EXCEPTION 
		WHEN NO_DATA THEN 
			DBMS_OUTPUT.PUT_LINE('No se encontro articulos con esa ID');
	END; 
	SELECT TIPO_ARTICULO INTO v_tipo_articulo FROM B_ARTICULOS WHERE ID = v_id_producto; 
	SELECT NVL(MAX(ID_PRODUCCION),0) + 1 INTO v_id_produccion FROM EX_PRODUCCION;
	
	-- Validar si es un producto 
	IF v_tipo_articulo = 'P' THEN 
		INSERT INTO EX_PRODUCCION (ID_PRODUCTO, CANTIDAD_A_PRODUCIR, FECHA_ORDEN) 
		VALUES (v_id_producto, v_cantidad_producir, TO_DATE(v_fecha_orden, 'DD/MM/YYYY')); 
		COMMIT; 
		
		INSERT INTO EX_MOV_PRODUCCION (ID_PRODUCCION, ID_INSUMO, CANTIDAD)
           SELECT v_id_produccion,
                  id_insumo,
                  (proporcion * NVL(v_cantidad_producir,0)) cantidad
             FROM EX_INSUMOS
            WHERE ID_PRODUCTO = v_id_producto;
		COMMIT; 
	ELSE 
		RAISE EX_NO_PROD; 
	END IF; 
EXCEPTION
	WHEN EX_NO_PROD THEN 
		DBMS_OUTPUT.PUT_LINE('No es un producto');
	WHEN OTHERS THEN 
		DBMS_OUTPUT.PUT_LINE('Error inesperado');

END; 
/ 
	
	
	

			

