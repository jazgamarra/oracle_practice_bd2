/*
Cree en la base de datos el tipo de datos CLIENTES como un varray de un máximo de 50
elementos, compuesto de la siguiente estructura:
	ID_CLIENTE
	NOMBRE_CLIENTE 
*/
-- crear una estructura para almacenar los datos 
CREATE OR REPLACE TYPE T_CLIENTE_2 AS OBJECT (
	ID_CLIENTE NUMBER,	
	NOMBRE VARCHAR2(40)
);

-- crear varray
CREATE OR REPLACE TYPE VARRAY_CLIENTES AS VARRAY(50) OF T_CLIENTE_2; 

-- probar el varray 
DECLARE 
	clientes VARRAY_CLIENTES := varray_clientes(); 
BEGIN
	clientes.extend(); 
	clientes(1) := T_CLIENTE_2(10, 'jaz'); 
	 DBMS_OUTPUT.PUT_LINE('ID: ' || clientes(1).ID_CLIENTE || ' NOMBRE: ' ||  clientes(1).NOMBRE);
END; 

/*
Cree la tabla relacional VENDEDORES, compuesta de las siguientes columnas
	CEDULA_VENDEDOR
	NOMBRE_VENDEDOR
	CLIENTES_VENDEDOR CLIENTES;
*/

CREATE TABLE VENDEDORES (
	CEDULA_VENDEDOR NUMBER, 
	NOMBRE_VENDEDOR VARCHAR2(30),
	CLIENTES_VENDEDOR VARRAY_CLIENTES
);

/*
Cree el procedimiento P_LLENAR TABLA que deberá buscar los vendedores (a partir de las ventas
realizadas en B_VENTAS), y determinar a cuántos clientes (personas) han vendido, llenando la tabla
de vendedores. Preste atención al campo de tipo objeto

 */

-- ver empleados que hicieron ventas 
SELECT DISTINCT VEN.CEDULA_VENDEDOR, EMP.NOMBRE || ' ' || EMP.APELLIDO NOMBRE_VENDEDOR 
FROM B_VENTAS VEN
JOIN B_EMPLEADOS EMP ON VEN.CEDULA_VENDEDOR = EMP.CEDULA 
JOIN B_PERSONAS PER ON PER.ID = VEN.ID_CLIENTE;

-- ver clientes por empleado 
SELECT VEN.CEDULA_VENDEDOR, PER.NOMBRE || ' ' || PER.APELLIDO NOMBRE_CLIENTE, PER.CEDULA CEDULA_CLIENTE
FROM B_VENTAS VEN
JOIN B_PERSONAS PER ON PER.ID = VEN.ID_CLIENTE
WHERE NOMBRE IS NOT NULL;

-- crear el procedimiento 
CREATE OR REPLACE PROCEDURE P_LLENAR_TABLA IS
    CURSOR C_EMPLEADOS_CON_VENTAS IS
        SELECT DISTINCT VEN.CEDULA_VENDEDOR, EMP.NOMBRE || ' ' || EMP.APELLIDO AS NOMBRE_VENDEDOR
        FROM B_VENTAS VEN
        JOIN B_EMPLEADOS EMP ON VEN.CEDULA_VENDEDOR = EMP.CEDULA
        JOIN B_PERSONAS PER ON PER.ID = VEN.ID_CLIENTE;

    CURSOR C_ALL_VENTAS IS
        SELECT VEN.CEDULA_VENDEDOR, PER.NOMBRE || ' ' || PER.APELLIDO AS NOMBRE_CLIENTE, PER.CEDULA AS CEDULA_CLIENTE
        FROM B_VENTAS VEN
        JOIN B_PERSONAS PER ON PER.ID = VEN.ID_CLIENTE;

    V_CONT NUMBER := 0;
    V_CLIENTE T_CLIENTE_2; -- Declarar una variable para almacenar el cliente.
	VARRAY_AUXILIAR VARRAY_CLIENTES := VARRAY_CLIENTES(); 
	id_cliente NUMBER; 
BEGIN
    FOR EMPLEADO IN C_EMPLEADOS_CON_VENTAS LOOP
        -- Inicializar la variable del cliente por cada empleado.
        V_CLIENTE := T_CLIENTE_2(NULL, NULL);

        INSERT INTO VENDEDORES (CEDULA_VENDEDOR, NOMBRE_VENDEDOR, CLIENTES_VENDEDOR)
        VALUES (EMPLEADO.CEDULA_VENDEDOR, EMPLEADO.NOMBRE_VENDEDOR, VARRAY_CLIENTES(V_CLIENTE)); -- Pasar la variable del cliente.

        FOR VENTA IN C_ALL_VENTAS LOOP
            IF VENTA.CEDULA_VENDEDOR = EMPLEADO.CEDULA_VENDEDOR THEN
                V_CONT := V_CONT + 1;
         		
               	SELECT ID INTO ID_CLIENTE FROM TAB_CLIENTES C WHERE C.CLIENTE.NOMBRE || ' ' || C.CLIENTE.APELLIDO = VENTA.NOMBRE_CLIENTE; 
               	
                -- Extender el varray en la variable V_CLIENTE y luego actualizarlo en la tabla VENDEDORES.
                VARRAY_AUXILIAR.EXTEND;
                VARRAY_AUXILIAR(V_CONT) := T_CLIENTE_2(ID_CLIENTE, VENTA.NOMBRE_CLIENTE);
            END IF;
        END LOOP;

        -- Actualizar la fila de VENDEDORES con el varray completo.
        UPDATE VENDEDORES
        SET CLIENTES_VENDEDOR = VARRAY_AUXILIAR
        WHERE CEDULA_VENDEDOR = EMPLEADO.CEDULA_VENDEDOR;

        V_CONT := 0; -- Restablecer V_CONT para el próximo empleado.
        VARRAY_AUXILIAR.delete();
    END LOOP;
END;

-- probar el procedimiento 
BEGIN 
	P_LLENAR_TABLA(); 
END;

-- consultar la tabla vendedores 
SELECT * FROM VENDEDORES; 
 
/*
Trate de actualizar elementos en la tabla. Por ejemplo trate de sustituir los clientes del empleado Juan Villalba con los del empleado Jorge Medina.
*/
UPDATE VENDEDORES SET CLIENTES_VENDEDOR = (SELECT CLIENTES_VENDEDOR FROM VENDEDORES WHERE CEDULA_VENDEDOR = 3009309) 
WHERE CEDULA_VENDEDOR = 1998898; 

/*
Cree en la base de datos el tipo de dato TAB_ARTICULOS como una tabla anidada de ARTICULOS que contenga:
	- ID_ARTICULO
	- NOMBRE_ARTICULO
*/
	
-- crear el objeto que se va a almacenar 
CREATE TYPE T_ARTICULO AS OBJECT (
    ID_ARTICULO NUMBER, 
    NOMBRE_ARTICULO VARCHAR2(100)
); 

-- crear la tabla que se va a almacenar como columna 
    CREATE TYPE TAB_ARTICULOS AS TABLE OF T_ARTICULO; 

/*
Cree la tabla relacional PROVEEDORES que contenga las siguientes columnas
	- ID_PROVEEDOR
	- NOMBRE_PROVEEDOR
	- ARTICULOS_PROVEIDOS 
*/

CREATE TABLE PROVEEDORES (
    ID_PROVEEDOR NUMBER,
    NOMBRE_PROVEEDOR VARCHAR2(30), 
    ARTICULOS_PROVEIDOS TAB_ARTICULOS
) NESTED TABLE ARTICULOS_PROVEIDOS STORE AS NT_PROVEEDORES; 

/*
Cree el procedimiento P_POBLAR_PROVEEDORES, el cual, en base a las COMPRAS realizadas,
deberá verificar todos los proveedores y los artículos que nos han proveído, llenando la tabla
PROVEEDORES.
 */

-- datos que usaremos para poblar las tablas 
SELECT PER.ID ID_PROVEEDOR, DET.ID_ARTICULO, ART.NOMBRE 
FROM B_PERSONAS PER 
JOIN B_COMPRAS COM ON COM.ID_PROVEEDOR = PER.ID
JOIN B_DETALLE_COMPRAS DET ON DET.ID_COMPRA = COM.ID
JOIN B_ARTICULOS ART ON ART.ID = DET.ID_ARTICULO 
ORDER BY PER.ID; 

-- proveedores 
SELECT DISTINCT PER.ID ID_PROVEEDOR, PER.NOMBRE || ' ' || PER.APELLIDO NOMBRE_PROVEEDOR
FROM B_PERSONAS PER 
JOIN B_COMPRAS COM ON COM.ID_PROVEEDOR = PER.ID
WHERE ES_PROVEEDOR = 'S'; 

-- crear procedimiento 
CREATE OR REPLACE PROCEDURE P_POBLAR_PROVEEDORES 
IS 
	CURSOR c_proveedores IS 
		SELECT DISTINCT PER.ID ID_PROVEEDOR, PER.NOMBRE || ' ' || PER.APELLIDO NOMBRE_PROVEEDOR
		FROM B_PERSONAS PER 
		JOIN B_COMPRAS COM ON COM.ID_PROVEEDOR = PER.ID
		WHERE ES_PROVEEDOR = 'S'; 

	CURSOR c_articulos(id_pro NUMBER) IS 
		SELECT PER.ID ID_PROVEEDOR, DET.ID_ARTICULO, ART.NOMBRE NOMBRE_ARTICULO
		FROM B_PERSONAS PER 
		JOIN B_COMPRAS COM ON COM.ID_PROVEEDOR = PER.ID
		JOIN B_DETALLE_COMPRAS DET ON DET.ID_COMPRA = COM.ID
		JOIN B_ARTICULOS ART ON ART.ID = DET.ID_ARTICULO 
		WHERE PER.ID = ID_PRO; 
	
	AUX TAB_ARTICULOS := TAB_ARTICULOS(); 
	V_CONTADOR NUMBER := 0; 

BEGIN 
	FOR PROVEEDOR IN C_PROVEEDORES LOOP 
		V_CONTADOR := 1;
		AUX.DELETE(); 
	
		FOR ART IN C_ARTICULOS(PROVEEDOR.ID_PROVEEDOR) LOOP
			AUX.EXTEND(); 
			AUX(V_CONTADOR) := T_ARTICULO(ART.ID_ARTICULO, ART.NOMBRE_ARTICULO);
--			DBMS_OUTPUT.PUT_LINE('Proveedor: ' || PROVEEDOR.ID_PROVEEDOR || ' Articulos: ' || AUX(V_CONTADOR).nombre_articulo);
			V_CONTADOR := V_CONTADOR + 1; 
		END LOOP;
		
		INSERT INTO PROVEEDORES VALUES (PROVEEDOR.ID_PROVEEDOR, PROVEEDOR.NOMBRE_PROVEEDOR, AUX);  
		
	END LOOP; 
END; 

-- ver datos de la nested table 
SELECT id_proveedor, nombre_proveedor, id_articulo, nombre_articulo
FROM PROVEEDORES p, TABLE(p.articulos_proveidos); 































