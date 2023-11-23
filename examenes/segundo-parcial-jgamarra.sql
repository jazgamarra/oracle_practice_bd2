/*
 * 
 * Base de datos II 
 * Segundo Examen Parcial 
 * 
 * Jazmin Maria del Lujan Gamarra Benitez 
 * jazgamarra@fpuna.edu.py 
 * 
 */

-------------------------------------------------------------------------------------------
-- TEMA 1 
-------------------------------------------------------------------------------------------

-- 1. El tipo TAB_CUENTA como una tabla anidada con los siguientes elementos:

	CREATE TYPE T_CUENTA AS OBJECT (
		CUENTA VARCHAR2(20),
		NOMBRE_CUENTA VARCHAR2(40),
		SALDO NUMBER (10)
	); 

    CREATE TYPE TAB_CUENTA AS TABLE OF T_CUENTA; 

-- 2. El tipo T_BALANCE como un objeto con los siguientes elementos:

   	-- cabecera del objeto 
    CREATE OR REPLACE TYPE T_BALANCE AS OBJECT (
	    EJERCICIO NUMBER (4),
	    BALANCE TAB_CUENTA,
		MEMBER PROCEDURE GENERAR_BALANCE,
		MEMBER PROCEDURE IMPRIMIR_BALANCE
	);  
	
	-- cuerpo del objeto 
	CREATE OR REPLACE TYPE BODY T_BALANCE IS 
		
		-- procedimiento generar balance 
		MEMBER PROCEDURE GENERAR_BALANCE IS
			CURSOR C_CONSULTAR_CUENTA (COD NUMBER) IS 
				SELECT CODIGO_CTA, NOMBRE_CTA ,  
				(SELECT CASE  C.ORDEN 
				    WHEN 'C' THEN SUM (ACUM_CREDITO - ACUM_DEBITO)
				    WHEN 'D' THEN SUM (ACUM_DEBITO - ACUM_CREDITO) END  
				FROM B_MAYOR 
				WHERE CODIGO_CTA = C.CODIGO_CTA
				) SALDO
				FROM B_CUENTAS C
				START WITH codigo_cta = COD
				CONNECT BY PRIOR CODIGO_CTA = CTA_SUPERIOR; 

			CURSOR C_CUENTAS_CONTABLES IS 
				SELECT codigo_cta FROM B_CUENTAS 
				WHERE NOMBRE_CTA IN ('ACTIVO', 'PASIVO', 'PATRIMONIO'); 
			
		BEGIN 
			FOR CC IN C_CUENTAS_CONTABLES LOOP 
				FOR S IN C_CONSULTAR_CUENTA(CC.CODIGO_CTA) LOOP
					SELF.BALANCE.EXTEND(); 
					SELF.BALANCE (S.CODIGO_CTA) := T_CUENTA(S.CODIGO_CTA, S.NOMBRE_CTA, S.SALDO); 
				END LOOP; 
			END LOOP; 
		END; 
	
		-- procedimiento imprimir balance 
		MEMBER PROCEDURE IMPRIMIR_BALANCE IS
			V_INDICE NUMBER; 
		BEGIN 
			V_INDICE := SELF.BALANCE.FIRST;

	 		WHILE V_INDICE <= SELF.BALANCE.LAST LOOP
			 	 DBMS_OUTPUT.PUT_LINE('Nro. de cuenta: ' || SELF.BALANCE(V_INDICE).CUENTA); 
			 	 DBMS_OUTPUT.PUT_LINE('Nombre de la cuenta: ' || SELF.BALANCE(V_INDICE).NOMBRE_CUENTA); 
			 	 DBMS_OUTPUT.PUT_LINE('Saldo: ' || SELF.BALANCE(V_INDICE).SALDO); 
			 	 DBMS_OUTPUT.PUT_LINE(' '); 
			 	 V_INDICE := SELF.BALANCE.NEXT(V_INDICE);
			 END LOOP;
		END; 
	END; 

-------------------------------------------------------------------------------------------
-- TEMA 2 
-------------------------------------------------------------------------------------------

-- 3. Cree el o los triggers requeridos sobre la tabla B_POSICION_ACTUAL para implementar las siguientes reglas de
-- negocio, cuidando que no se produzca el error de tabla mutante (se verificará la sintaxis)
 
	-- crear un paquete para guardar los datos 
	CREATE OR REPLACE PACKAGE PACK_EMPLEADOS
	IS
		TYPE R_EMP IS RECORD (
			
			CEDULA_EMPLEADO NUMBER,
			CANT_POSICIONES NUMBER,
			SUELDO NUMBER,
			CEDULA_JEFE NUMBER
		);
		TYPE T_EMPLEADOS IS TABLE OF R_EMP INDEX BY BINARY_INTEGER;
		T_EMP T_EMPLEADOS;
	END;

	-- trigger a nivel de sentencias 
	CREATE OR REPLACE TRIGGER T_VERIF_EMPLEADOS  
		BEFORE UPDATE OR INSERT ON B_POSICION_ACTUAL 
	DECLARE 
		CURSOR C_EMPLEADOS_CONTRATADOS IS 
			SELECT PO.CEDULA CEDULA_EMPLEADO,
			(SELECT COUNT(*) FROM B_POSICION_ACTUAL p WHERE P.CEDULA=PO.CEDULA AND FECHA_FIN IS NULL)
			CANT_POSICIONES, CA.ASIGNACION SUELDO, CEDULA_JEFE
			FROM B_POSICION_ACTUAL PO 
			JOIN B_CATEGORIAS_SALARIALES CA ON CA.COD_CATEGORIA = PO.COD_CATEGORIA 
			JOIN B_EMPLEADOS EMP ON EMP.CEDULA = PO.CEDULA 
			GROUP BY PO.CEDULA, CA.ASIGNACION, CEDULA_JEFE; 
		 v_contador NUMBER;
	BEGIN	
		-- vaciar la variable de paquete 
		PACK_EMPLEADOS.T_EMP.DELETE;
		
		-- guardar datos en el paquete 
		 FOR REG IN C_EMPLEADOS_CONTRATADOS LOOP
			PACK_EMPLEADOS.T_EMP(REG.CEDULA_EMPLEADO).CEDULA_EMPLEADO := REG.CEDULA_EMPLEADO;
			PACK_EMPLEADOS.T_EMP(REG.CEDULA_EMPLEADO).CANT_POSICIONES := REG.CANT_POSICIONES;
			PACK_EMPLEADOS.T_EMP(REG.CEDULA_EMPLEADO).SUELDO := REG.SUELDO;
			PACK_EMPLEADOS.T_EMP(REG.CEDULA_EMPLEADO).CEDULA_JEFE := REG.CEDULA_JEFE;
		 END LOOP;
		 
	 	 -- imprimir datos del paquete
		  v_contador := PACK_EMPLEADOS.T_EMP.FIRST;
		  WHILE v_contador <= PACK_EMPLEADOS.T_EMP.LAST LOOP
		 	 DBMS_OUTPUT.PUT_LINE('Cedula del empleado: ' || PACK_EMPLEADOS.T_EMP(v_contador).CEDULA_EMPLEADO); 
		 	 DBMS_OUTPUT.PUT_LINE('Cantidad de posiciones que ocupa: ' || PACK_EMPLEADOS.T_EMP(v_contador).CANT_POSICIONES); 
		 	 DBMS_OUTPUT.PUT_LINE('Sueldo asignado: ' || PACK_EMPLEADOS.T_EMP(v_contador).SUELDO); 
		 	 DBMS_OUTPUT.PUT_LINE('Cedula del jefe: ' || PACK_EMPLEADOS.T_EMP(v_contador).CEDULA_JEFE); 
		 	 DBMS_OUTPUT.PUT_LINE(' '); 
		 	 v_contador :=  PACK_EMPLEADOS.T_EMP.NEXT(v_contador);
		 END LOOP;
	END; 

	-- trigger a nivel de fila 
	CREATE OR REPLACE TRIGGER T_VALIDAR_EMPLEADOS
		AFTER UPDATE OR INSERT ON B_POSICION_ACTUAL 
		FOR EACH ROW
	BEGIN
			-- no puede tener dos categorias 
			IF :NEW.FECHA_FIN IS NULL AND PACK_EMPLEADOS.T_EMP(:NEW.CEDULA).CANT_POSICIONES != 0 THEN 
				RAISE_APPLICATION_ERROR (-20001, '(!!!) No puede asignar dos posiciones al mismo empleado. '); 
			END IF; 
		
			-- no puede ganar mas que su jefe 
			IF PACK_EMPLEADOS.T_EMP(:NEW.CEDULA).SUELDO > PACK_EMPLEADOS.T_EMP(PACK_EMPLEADOS.T_EMP(:NEW.CEDULA).CEDULA_JEFE).SUELDO THEN 
				RAISE_APPLICATION_ERROR (-20002, '(!!!) Un empleado no puede ganar mas que su jefe. ');
			END IF; 
	END; 


-------------------------------------------------------------------------------------------
-- TEMA 3 
-------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_BORRAR(p_resultado OUT NUMBER) AS
    CURSOR C_ALL_OBJECTS IS 
        SELECT object_name, object_type
        FROM user_objects
        WHERE object_name NOT LIKE 'B\_%' ESCAPE '\' AND object_name NOT LIKE 'D\_%' ESCAPE '\';
    V_TIPO_OBJETO VARCHAR2(30);
    V_NOMBRE_OBJETO VARCHAR2(128);
    V_SQL VARCHAR2(200);
    V_NRO_ERRORES NUMBER := 0;
BEGIN
    p_resultado := 0;  
 
   	-- iterar sobre todos los objetos 
    FOR obj IN C_ALL_OBJECTS LOOP
       V_NOMBRE_OBJETO := obj.object_name;
       V_TIPO_OBJETO := obj.object_type;
 		
       IF V_TIPO_OBJETO NOT IN ('INDEX', 'PROCEDURE') THEN
          BEGIN
             V_SQL := 'DROP ' || V_TIPO_OBJETO || ' ' || V_NOMBRE_OBJETO ;
             EXECUTE IMMEDIATE V_SQL;
          EXCEPTION
             WHEN OTHERS THEN
                V_NRO_ERRORES := V_NRO_ERRORES + 1;
          END;
       END IF;
    END LOOP;
 
    -- si se encontraron errores 
    IF V_NRO_ERRORES > 0 THEN
       p_resultado := 1;
    END IF;
END;

