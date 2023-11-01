
/* Cree el procedimiento P_ESTADISTICA_ARTICULOS de la siguiente manera:
 Cree el tipo de dato (registro) denominado r_articulos conformado por los siguientes campos:
 id_articulo
 Nombre_articulo
 Monto_compras
 Monto_ventas
 Cree una tabla indexada cuyos componentes sean datos del tipo r_articulos
 Llene la tabla con los datos de compras y ventas de artículos durante el 2011
 En un ciclo FOR... LOOP, imprima el contenido de la tabla.
*/

-- Datos que guardaremos en la tabla indexada 
SELECT ART.ID, ART.NOMBRE, SUM(DCO.PRECIO_COMPRA*DCO.CANTIDAD) COMPRA, SUM(DVE.CANTIDAD * DVE.PRECIO) VENTA 
FROM B_ARTICULOS ART 
JOIN B_DETALLE_COMPRAS DCO ON DCO.ID_ARTICULO = ART.ID 
JOIN B_DETALLE_VENTAS DVE ON DVE.ID_ARTICULO = ART.ID  
JOIN B_COMPRAS COM ON COM.ID = DCO.ID_COMPRA 
JOIN B_VENTAS VEN ON VEN.ID = DVE.ID_VENTA 
WHERE EXTRACT(YEAR FROM COM.FECHA) = 2018 OR EXTRACT(YEAR FROM VEN.FECHA) = 2018
GROUP BY ART.ID, ART.NOMBRE; 

--Creamos el procedimiento 
CREATE OR REPLACE PROCEDURE P_ESTADISTICA_ARTICULOS IS 
	TYPE R_ARTICULOS IS RECORD (
		ID_ARTICULO B_ARTICULOS.ID%TYPE, 
		NOMBRE_ART B_ARTICULOS.NOMBRE%TYPE, 
		MONTO_COMPRAS NUMBER,
		MONTO_VENTAS NUMBER
	); 
	TYPE T_ARTICULOS IS TABLE OF R_ARTICULOS INDEX BY BINARY_INTEGER; 
	-- Declaramos un cursor con los datos a cargar en los registros y tabla 
	CURSOR C_COMPRAS_VENTAS IS 
		SELECT ART.ID, ART.NOMBRE, SUM(DCO.PRECIO_COMPRA*DCO.CANTIDAD) COMPRA, SUM(DVE.CANTIDAD * DVE.PRECIO) VENTA 
		FROM B_ARTICULOS ART 
		JOIN B_DETALLE_COMPRAS DCO ON DCO.ID_ARTICULO = ART.ID 
		JOIN B_DETALLE_VENTAS DVE ON DVE.ID_ARTICULO = ART.ID  
		JOIN B_COMPRAS COM ON COM.ID = DCO.ID_COMPRA 
		JOIN B_VENTAS VEN ON VEN.ID = DVE.ID_VENTA 
		WHERE EXTRACT(YEAR FROM COM.FECHA) = 2018 OR EXTRACT(YEAR FROM VEN.FECHA) = 2018
		GROUP BY ART.ID, ART.NOMBRE; 
	R_ART R_ARTICULOS; 
	T_ART T_ARTICULOS; 
	V_CONTADOR NUMBER := 0; 
BEGIN
	FOR ART IN C_COMPRAS_VENTAS LOOP 
		-- Guardar los datos en registros 
		V_CONTADOR := V_CONTADOR + 1; 
		R_ART.NOMBRE_ART := ART.NOMBRE; 
		R_ART.ID_ARTICULO := ART.ID;
		R_ART.MONTO_COMPRAS := ART.COMPRA; 
		R_ART.MONTO_VENTAS := ART.VENTA;
		-- Guardar el registro en la tabla 
		T_ART(V_CONTADOR) := R_ART; 
	END LOOP; 
	-- Imprimir cada fila de la tabla 
	FOR i IN T_ART.FIRST .. T_ART.LAST LOOP
	    DBMS_OUTPUT.PUT_LINE('ID_ARTICULO: ' || T_ART(i).ID_ARTICULO);
	    DBMS_OUTPUT.PUT_LINE('NOMBRE_ART: ' || T_ART(i).NOMBRE_ART);
	    DBMS_OUTPUT.PUT_LINE('MONTO_COMPRAS: ' || T_ART(i).MONTO_COMPRAS);
	    DBMS_OUTPUT.PUT_LINE('MONTO_VENTAS: ' || T_ART(i).MONTO_VENTAS);
  	END LOOP;
END; 
COMMIT; 

-- Llamar al procedimiento 
BEGIN
	P_ESTADISTICA_ARTICULOS(); 
END; 

/*
Desarrolle un PL/SQL anónimo que le permitirá declarar una tabla indexada que tenga:
- mes
- total_ventas
- volumen_ventas (cantidad)
 El programa deberá generar un resultado como el que se muestra para todo el año 2011. 
 */
-- Verificar los datos que debemos cargar en la tabla 
SELECT EXTRACT(MONTH FROM VEN.FECHA) MES, SUM(DET.CANTIDAD) TOTAL, SUM(DET.PRECIO*DET.CANTIDAD ) VOLUMEN 
FROM B_VENTAS VEN 
JOIN B_DETALLE_VENTAS DET ON DET.ID_VENTA = VEN.ID 
WHERE EXTRACT(year FROM VEN.FECHA) = 2018
GROUP BY VEN.FECHA; 

DECLARE 
	CURSOR C_DATOS IS 
		SELECT EXTRACT(MONTH FROM VEN.FECHA) MES, SUM(DET.CANTIDAD) TOTAL, SUM(DET.PRECIO*DET.CANTIDAD ) VOLUMEN 
		FROM B_VENTAS VEN 
		JOIN B_DETALLE_VENTAS DET ON DET.ID_VENTA = VEN.ID 
		WHERE EXTRACT(year FROM VEN.FECHA) = 2018
		GROUP BY VEN.FECHA; 

	TYPE R_ROW IS RECORD (
		MES NUMBER, TOTAL_VENTAS NUMBER, VOLUMEN_VENTAS NUMBER
	);
	TYPE T_ESTADISTICA IS TABLE OF R_ROW INDEX BY BINARY_INTEGER; 
	R_TEMP R_ROW; 
	TABLA_ESTADISTICA T_ESTADISTICA; 
	V_CONTADOR NUMBER := 0; 
BEGIN 
	-- Guardar datos en la tabla indexada 
	FOR DATO IN C_DATOS LOOP 
		R_TEMP.MES := DATO.MES; 
		R_TEMP.TOTAL_VENTAS := DATO.TOTAL; 
		R_TEMP.VOLUMEN_VENTAS := DATO.VOLUMEN; 
		TABLA_ESTADISTICA(V_CONTADOR) := R_TEMP; 
		V_CONTADOR := v_contador + 1; 
		 DBMS_OUTPUT.PUT_LINE('contador: ' || v_contador);
	END LOOP; 
	
	-- Mostrar los datos 
	FOR n IN TABLA_ESTADISTICA.FIRST .. TABLA_ESTADISTICA.LAST LOOP
	    DBMS_OUTPUT.PUT_LINE('Mes: ' || TABLA_ESTADISTICA(n).MES);
	    DBMS_OUTPUT.PUT_LINE('Total: ' || TABLA_ESTADISTICA(n).TOTAL_VENTAS);
	    DBMS_OUTPUT.PUT_LINE('Monto: ' || TABLA_ESTADISTICA(n).VOLUMEN_VENTAS);
	    DBMS_OUTPUT.PUT_LINE('------------------------------');
  	END LOOP;

END; 

/*
Desarrolle el procedimiento P_DISTRIBUIR_CLIENTES que se encargará de distribuir los clientes
entre los empleados que son vendedores, y posteriormente muestre dicha distribución como un
tablero:
a) Declarar un tipo de dato registro T_REG compuesto de los campos:
	 NOM_APE VARCHAR (200),
	 TELEFONO VARCHAR2(15),
	 CEDULA_JEFE VARCHAR2(15),
	 CANT_CLIENTE NUMBER (5)
b) Declarar una tabla indexada del tipo T_REG.
c) Llenar la tabla con los datos de los empleados que ocupan actualmente el cargo de vendedor, no olvide
indexar la tabla por cédula del vendedor. Para obtener el campo CANT_CLIENTE, debe calcular la
cantidad total de clientes existentes y distribuir equitativamente dicha cantidad entre los vendedores
existentes. SI la distribución no es exacta, la diferencia quedará en el último elemento.
d) Por último, deberá imprimir los elementos de la tabla.
	 El tablero debe lucir de la siguiente manera:
	 En caso de que tengamos 3 vendedores y un total de 20 clientes

*/
-- datos de los empleados 
SELECT EMP.NOMBRE || ' ' || EMP.APELLIDO NOMBRE, EMP.TELEFONO, EMP.CEDULA_JEFE 
FROM B_EMPLEADOS EMP
JOIN B_POSICION_ACTUAL PA ON PA.CEDULA = EMP.CEDULA
JOIN B_CATEGORIAS_SALARIALES CA ON CA.COD_CATEGORIA = PA.COD_CATEGORIA 
WHERE CA.NOMBRE_CAT LIKE 'Vendedor %';

-- cantidad de clientes
SELECT floor(count(*)/3) FROM b_personas WHERE es_cliente = 'S'; 
SELECT count(*) FROM b_personas WHERE es_cliente = 'S'; 

-- cantidad de vendedores 
SELECT count(*)
FROM B_EMPLEADOS EMP
JOIN B_POSICION_ACTUAL PA ON PA.CEDULA = EMP.CEDULA
JOIN B_CATEGORIAS_SALARIALES CA ON CA.COD_CATEGORIA = PA.COD_CATEGORIA 
WHERE CA.NOMBRE_CAT LIKE 'Vendedor %';


-- crear el procedimiento 
CREATE OR REPLACE PROCEDURE P_DISTRIBUIR_CLIENTES
IS 
	CURSOR C_VENDEDORES IS 
		SELECT EMP.CEDULA, EMP.NOMBRE || ' ' || EMP.APELLIDO NOMBRE, EMP.TELEFONO, EMP.CEDULA_JEFE 
		FROM B_EMPLEADOS EMP
		JOIN B_POSICION_ACTUAL PA ON PA.CEDULA = EMP.CEDULA
		JOIN B_CATEGORIAS_SALARIALES CA ON CA.COD_CATEGORIA = PA.COD_CATEGORIA 
			WHERE CA.NOMBRE_CAT LIKE 'Vendedor %';
	TYPE T_REG IS RECORD (
		NOM_APE VARCHAR (200),
		TELEFONO VARCHAR2(15),
		CEDULA_JEFE VARCHAR2(15),
		CANT_CLIENTE NUMBER (5)
	); 

	TYPE T_VENDEDORES IS TABLE OF T_REG INDEX BY BINARY_INTEGER; 
	TAB_VENDEDORES T_VENDEDORES; 
	V_VENDEDORES NUMBER; 
	V_CLIENTES NUMBER ; 
	v_contador NUMBER := 0; 
		
BEGIN
	-- calcular la cantidad total de clientes 
	SELECT count(*) INTO V_CLIENTES FROM b_personas WHERE es_cliente = 'S'; 

	-- calcular la cantidad de vendedores 
	SELECT count(*) INTO V_VENDEDORES FROM B_EMPLEADOS EMP 
	JOIN B_POSICION_ACTUAL PA ON PA.CEDULA = EMP.CEDULA
	JOIN B_CATEGORIAS_SALARIALES CA ON CA.COD_CATEGORIA = PA.COD_CATEGORIA 
	WHERE CA.NOMBRE_CAT LIKE 'Vendedor %'; 

	-- llenar la tabla 
	FOR VEND IN C_VENDEDORES LOOP
		TAB_VENDEDORES(VEND.CEDULA).NOM_APE := VEND.NOMBRE;
		TAB_VENDEDORES(VEND.CEDULA).TELEFONO := VEND.TELEFONO;
		TAB_VENDEDORES(VEND.CEDULA).CEDULA_JEFE := VEND.CEDULA_JEFE ;
		TAB_VENDEDORES(VEND.CEDULA).CANT_CLIENTE := floor(v_clientes/v_vendedores);
	END LOOP; 

	-- verificar si hay sobrantes para modificar el ultimo 
	IF  floor(v_clientes/v_vendedores) * v_vendedores != v_vendedores THEN 
		tab_vendedores(tab_vendedores.last).cant_cliente :=  floor(v_clientes/v_vendedores) * (v_vendedores-1) - v_vendedores; 
	END IF; 

	-- mostrar los elementos de la tabla 
	v_contador := tab_vendedores.FIRST;

	 WHILE v_contador <= TAB_VENDEDORES.LAST LOOP
	 	 DBMS_OUTPUT.PUT_LINE('Nombre: ' || tab_vendedores(v_contador).NOM_APE); 
	 	 DBMS_OUTPUT.PUT_LINE('Telefono: ' || tab_vendedores(v_contador).CEDULA_JEFE); 
	 	 DBMS_OUTPUT.PUT_LINE('Cedula jefe: ' || tab_vendedores(v_contador).CEDULA_JEFE); 
	 	 DBMS_OUTPUT.PUT_LINE('Cantidad de clientes: ' || tab_vendedores(v_contador).CANT_CLIENTE); 
	 	 DBMS_OUTPUT.PUT_LINE(' '); 
	 	 v_contador := tab_vendedores.NEXT(v_contador);

	 END LOOP;
END; 

