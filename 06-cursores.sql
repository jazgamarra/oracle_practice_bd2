/*
 * Desarrolle un PL/SQL anónimo que calcule la liquidación de salarios del mes de Agosto del 2018. El
PL/SQL deberá realizar lo siguiente:
 Insertar un registro de cabecera de LIQUIDACIÓN correspondiente a agosto del 2018.
 Recorrer secuencialmente el archivo de empleados y calcular la liquidación de cada empleado de
la siguiente manera:
- salario básico = asignación correspondiente a la categoría de la posición vigente
- descuento por IPS = 9,5% del salario
- bonificaciónxventas= a la suma de la bonificación obtenida a partir de las ventas
realizadas por ese empleado en el mes de agosto del 2018 (la bonificación es calculada de
acuerdo a los artículos vendidos).
- líquido = salario básico – descuento x IPS + bonificación (si corresponde).
 Insertar la liquidación calculada en la PLANILLA con el ID de la cabecera de liquidación creada
 */
DECLARE
	V_ID_LIQ B_LIQUIDACION.ID%TYPE; 
	V_SALARIO_BASICO B_PLANILLA.SALARIO_BASICO%TYPE; 
	V_BONIFICACION B_PLANILLA.BONIFICACION_X_VENTAS%TYPE; 

	CURSOR C_EMPLEADOS IS 
		SELECT emp.CEDULA FROM B_EMPLEADOS EMP 
		JOIN B_POSICION_ACTUAL POS ON POS.CEDULA = EMP.CEDULA 
		WHERE emp.CEDULA NOT IN (SELECT CEDULA FROM B_EMPLEADOS MINUS SELECT CEDULA FROM B_POSICION_ACTUAL) AND  POS.FECHA_FIN IS NULL; 
BEGIN 
	-- Almacenar id de liquidacion 
	SELECT MAX(ID)+1 INTO V_ID_LIQ FROM B_LIQUIDACION; 
	
	-- Insertar un registro de cabecera de LIQUIDACIÓN correspondiente a agosto del 2018
	INSERT INTO B_LIQUIDACION (ID, FECHA_LIQUIDACION, ANIO, MES) VALUES 
		(V_ID_LIQ, TO_DATE('10/08/2018', 'DD/MM/YYYY'), 2018, 8); 
	
	FOR EMPLEADO IN C_EMPLEADOS LOOP 
		SELECT NVL(ASIGNACION, 0) INTO V_SALARIO_BASICO FROM B_CATEGORIAS_SALARIALES CAT
		JOIN B_POSICION_ACTUAL POS ON CAT.COD_CATEGORIA = POS.COD_CATEGORIA
		WHERE POS.CEDULA=EMPLEADO.CEDULA AND POS.FECHA_FIN IS NULL; 
		SELECT NVL(SUM(DET.CANTIDAD*DET.PRECIO*ART.PORC_COMISION), 0) INTO V_BONIFICACION FROM B_ARTICULOS ART, B_DETALLE_VENTAS DET, B_VENTAS VEN 
			WHERE ART.ID = DET.ID_ARTICULO AND VEN.ID = DET.ID_VENTA AND VEN.CEDULA_VENDEDOR = EMPLEADO.CEDULA AND EXTRACT(YEAR FROM VEN.FECHA) = 2018; 
		
		INSERT INTO B_PLANILLA (ID_LIQUIDACION, CEDULA, SALARIO_BASICO, DESCUENTO_IPS, BONIFICACION_X_VENTAS, LIQUIDO_COBRADO) 
		VALUES (V_ID_LIQ, EMPLEADO.CEDULA, V_SALARIO_BASICO, V_SALARIO_BASICO * 0.095, V_BONIFICACION,  V_SALARIO_BASICO - (V_SALARIO_BASICO * 0.095) + V_BONIFICACION); 
	
	END LOOP; 
	COMMIT;
END;

/*
 * Cree un bloque PL/SQL que mayorice los movimientos contables de febrero del 2019. Ud deberá
o Recorrer las cuentas imputables del Plan de cuentas
o Por cada cuenta, calcular el acumulado de débitos y crédi
 */

DECLARE 
	CURSOR C_CUENTAS IS 
		SELECT CODIGO_CTA FROM B_CUENTAS WHERE IMPUTABLE = 'S'; 
	
	V_CREDITO NUMBER(12); 
	V_DEBITO NUMBER(12); 
BEGIN
	FOR CUENTA IN C_CUENTAS LOOP 
		
		-- Extraer el debito
		SELECT NVL(SUM(IMPORTE), 0) INTO V_DEBITO
		FROM B_DIARIO_DETALLE DDE
		JOIN B_DIARIO_CABECERA DCA ON DDE.ID = DCA.ID 
		WHERE CODIGO_CTA = CUENTA.CODIGO_CTA AND DEBE_HABER = 'D'
		AND EXTRACT(MONTH FROM DCA.FECHA) = 2 AND EXTRACT(YEAR FROM DCA.FECHA) = 2019;
		
		-- Extraer el credito 
		SELECT NVL(SUM(IMPORTE), 0) INTO V_CREDITO
		FROM B_DIARIO_DETALLE DDE 
		JOIN B_DIARIO_CABECERA DCA ON DDE.ID = DCA.ID 
		WHERE CODIGO_CTA = CUENTA.CODIGO_CTA AND DEBE_HABER = 'C'
		AND EXTRACT(MONTH FROM DCA.FECHA) = 2 AND EXTRACT(YEAR FROM DCA.FECHA) = 2019;

		DBMS_OUTPUT.PUT_LINE('Cuenta ' || cuenta.codigo_cta || ' Credito '|| v_credito || ' Debito '|| v_debito);
		
		-- Insertar en el mayor 
		INSERT INTO BASEDATOS2.B_MAYOR (ID_MAYOR, CODIGO_CTA, ANIO, MES, ACUM_DEBITO, ACUM_CREDITO)
		VALUES((SELECT MAX(ID_MAYOR)+1 FROM B_MAYOR), CUENTA.CODIGO_CTA, 2019, 2, V_DEBITO, V_CREDITO);
	END LOOP;
	COMMIT; 
END; 
































