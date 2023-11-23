-------------------------------------------------------------------------------------------
-- TEMA 1 
-------------------------------------------------------------------------------------------
	
	-- 1. Cree en la BD el objeto T_SESION 
	-- cabecera del objeto
	CREATE OR REPLACE TYPE T_SESION AS OBJECT (
		FECHORA_INI DATE,
		FECHORA_FIN DATE,
		MEMBER FUNCTION VALIDAR_HORARIO (ID NUMBER) RETURN BOOLEAN
	); 

	-- cuerpo del objeto 
	CREATE OR REPLACE TYPE BODY T_SESION AS 
		MEMBER FUNCTION VALIDAR_HORARIO (ID NUMBER) RETURN BOOLEAN IS 
			V_INI DATE; 
			V_FIN DATE; 
			V_HORA VARCHAR2(5); 
		BEGIN 
			-- obtener los datos de la tabla tratamiento 
			SELECT FECHA_INICIO, FECHA_FIN, HORA_INICIO 
			INTO V_INI, V_FIN, V_HORA 
			FROM TRATAMIENTO, HORARIO 
			WHERE ID_TRATAMIENTO = ID; 
		
			-- validaciones 
			IF V_FIN IS NULL 
				AND SELF.FECHORA_INI >= V_INI
				AND V_HORA = TO_CHAR(SELF.FECHORA_INI, 'HH24:MI')
				AND TRUNC(SELF.FECHORA_FIN) = TRUNC(SELF.FECHORA_INI) 
				AND SELF.FECHORA_INI < SELF.FECHORA_FIN 
			THEN 
				RETURN TRUE;
			ELSE 
				RETURN FALSE;
			END IF; 						
		END; 
	END; 

	-- 2. Cree el tipo TAB_SESION como un VARRAY de 20 ocurrencias del tipo T_SESION.
	CREATE OR REPLACE TYPE TAB_SESION AS VARRAY(20) OF T_SESION; 

	-- 3. Incorpore en la tabla TRATAMIENTO el atributo SESIONES del tipo TAB_SESION. 
	ALTER TABLE TRATAMIENTO ADD SESIONES TAB_SESION; 

-------------------------------------------------------------------------------------------
-- TEMA 2 
-------------------------------------------------------------------------------------------

	-- cabecera del paquete 
	CREATE OR REPLACE PACKAGE PKG_TRATAMIENTO AS 
		FUNCTION F_CALCULAR_FIN (P_ID_TRAT NUMBER) RETURN DATE;
		PROCEDURE P_COMPLETAR_SESION (P_ID_TRAT NUMBER, FECHORA_INI DATE, FECHORA_FIN DATE); 
	END; 

	-- cuerpo del paquete 
	CREATE OR REPLACE PACKAGE BODY PKG_TRATAMIENTO IS  
		
		-- Calcular fin 
		FUNCTION F_CALCULAR_FIN (P_ID_TRAT NUMBER) RETURN DATE IS 
			V_NRO_SESIONES NUMBER; 
			V_FECHA DATE;  
			V_CONTADOR NUMBER := 1; 
			V_feriados NUMBER; 
		BEGIN 
			-- obtener los datos 
			SELECT NRO_SESIONES, FECHA_INICIO 
			INTO V_NRO_SESIONES, V_FECHA 
			FROM TRATAMIENTO
			WHERE ID_TRATAMIENTO = P_ID_TRAT;  
	 
				
			WHILE V_CONTADOR < V_NRO_SESIONES LOOP 
				-- ver si hay feriados 
				SELECT COUNT(*) INTO V_FERIADOS FROM FERIADO WHERE DIA_FERIADO = V_FECHA; 
	
				IF  V_FERIADOS = 0 
				AND TO_CHAR(V_FECHA, 'D') NOT IN ('6', '7')
				THEN
					V_CONTADOR := V_CONTADOR + 1; 	
				END IF; 
				V_FECHA := V_FECHA + 1;  
			END LOOP; 
			RETURN V_FECHA; 
		END; 
	
		-- Completar sesion 
		PROCEDURE P_COMPLETAR_SESION (P_ID_TRAT NUMBER, FECHORA_INI DATE, FECHORA_FIN DATE) IS 
			V_NUM NUMBER := 0;
			V_NUM_SESIONES NUMBER := 0; 
			V_SESION T_SESION; 
			V_VAL_OBJ BOOLEAN; 
			V_VARRAY_AUX TAB_SESION := TAB_SESION(); 
		BEGIN 
			-- Obtener la lista de sesiones 
			SELECT SESIONES, NRO_SESIONES INTO V_VARRAY_AUX, V_NUM_SESIONES FROM TRATAMIENTO T WHERE T.ID_TRATAMIENTO = P_ID_TRAT; 
		
			-- Sumar una sesion mas y verificar si no se sobrepasa el numero de sesiones que necesitamos 
			V_NUM := NVL(V_VARRAY_AUX.LAST, 0) + 1; 
			
			IF V_NUM = 1 THEN
				V_VARRAY_AUX := TAB_SESION(); 
			END IF;  
		
			IF V_NUM > V_NUM_SESIONES THEN 
				RAISE_APPLICATION_ERROR (-20001, '(!!!) Se llego al limite de sesiones. '); 
			END IF; 
		
			-- Instanciar variable de tipo T_SESION 
			V_SESION := T_SESION(FECHORA_INI, FECHORA_FIN); 
			V_VAL_OBJ := V_SESION.VALIDAR_HORARIO(P_ID_TRAT); 
		
			-- Si se pasan las validaciones... 
			IF V_VAL_OBJ THEN 
				-- Obtener la lista de sesiones 
				V_VARRAY_AUX.EXTEND(); 
				V_VARRAY_AUX(V_NUM) := V_SESION; 
				
				-- Actualizar la tabla 
				UPDATE TRATAMIENTO T SET SESIONES = V_VARRAY_AUX WHERE T.ID_TRATAMIENTO = P_ID_TRAT; 
			END IF; 
		END;
END; 

-- Probar funciones 
BEGIN 
	DBMS_OUTPUT.PUT_LINE(F_CALCULAR_FIN(1200)); 
END; 

BEGIN 
	P_COMPLETAR_SESION(1200, TRUNC(SYSDATE) + 9/24, TRUNC(SYSDATE) + 10/24);
END; 

-------------------------------------------------------------------------------------------
-- TEMA 3 
-------------------------------------------------------------------------------------------
	-- Crear un paquete para almacenar los datos que necesitaremos consultar 
	CREATE OR REPLACE PACKAGE PACK_PERS_TRAT
		IS
			TYPE R_TRAT IS RECORD (
				CEDULA_PAC VARCHAR2(11),
				COD_TERAP NUMBER,
				F_INICIO DATE,
				F_FIN DATE, 
				TURNO NUMBER
			);
			TYPE T_TRAT IS TABLE OF R_TRAT INDEX BY BINARY_INTEGER;
			T_TRATAMIENTOS T_TRAT;
		END; 

	-- Guardar datos dentro del paquete 
	CREATE OR REPLACE TRIGGER T_GUAR_TURNOS_TERAP  
		BEFORE UPDATE OR INSERT ON TRATAMIENTO  
	DECLARE 
		CURSOR C_TRATAMIENTOS IS 
			SELECT CEDULA, COD_FISIOTERAPEUTA, FECHA_INICIO, FECHA_FIN, NRO_TURNO FROM TRATAMIENTO
			WHERE FECHA_FIN IS NULL; 
		 v_contador NUMBER := 0;
	BEGIN	
		-- vaciar la variable de paquete 
		PACK_PERS_TRAT.T_TRATAMIENTOS.DELETE;
		
		-- guardar datos en el paquete 
		FOR REG IN C_TRATAMIENTOS LOOP 
			PACK_PERS_TRAT.T_TRATAMIENTOS(V_CONTADOR).CEDULA_PAC := REG.CEDULA;
			PACK_PERS_TRAT.T_TRATAMIENTOS(V_CONTADOR).COD_TERAP := REG.COD_FISIOTERAPEUTA;
			PACK_PERS_TRAT.T_TRATAMIENTOS(V_CONTADOR).F_INICIO := REG.FECHA_INICIO;
			PACK_PERS_TRAT.T_TRATAMIENTOS(V_CONTADOR).F_FIN := REG.FECHA_FIN;
			PACK_PERS_TRAT.T_TRATAMIENTOS(V_CONTADOR).TURNO := REG.NRO_TURNO;

			V_CONTADOR := V_CONTADOR + 1; 
		END LOOP;
	
		-- mostrar datos guardados xd 
		v_contador := PACK_PERS_TRAT.T_TRATAMIENTOS.FIRST;
		WHILE  v_contador <= PACK_PERS_TRAT.T_TRATAMIENTOS.LAST LOOP
		 	 DBMS_OUTPUT.PUT_LINE('Paciente: ' || PACK_PERS_TRAT.T_TRATAMIENTOS(v_contador).CEDULA_PAC); 
		 	 DBMS_OUTPUT.PUT_LINE('Terapeuta: ' || PACK_PERS_TRAT.T_TRATAMIENTOS(v_contador).COD_TERAP); 
		 	 DBMS_OUTPUT.PUT_LINE('Turno: ' || PACK_PERS_TRAT.T_TRATAMIENTOS(v_contador).TURNO); 
		 	 DBMS_OUTPUT.PUT_LINE(' '); 
		 	 v_contador :=  PACK_PERS_TRAT.T_TRATAMIENTOS.NEXT(v_contador);
		 END LOOP;
	END; 

	-- Crear el trigger a nivel de fila 
	CREATE OR REPLACE TRIGGER T_VERIF_TURNOS_TERAP 
		BEFORE UPDATE OR INSERT ON TRATAMIENTO 
		FOR EACH ROW
	DECLARE 
		v_contador NUMBER; 
	BEGIN
		 V_contador := PACK_PERS_TRAT.T_TRATAMIENTOS.FIRST;
		
		 WHILE v_contador <= PACK_PERS_TRAT.T_TRATAMIENTOS.LAST LOOP
			 -- verifica si es el mismo doc o paciente 
		 	IF PACK_PERS_TRAT.T_TRATAMIENTOS(v_contador).CEDULA_PAC = :NEW.CEDULA 
		 	OR PACK_PERS_TRAT.T_TRATAMIENTOS(v_contador).COD_TERAP = :NEW.COD_FISIOTERAPEUTA THEN
		 		-- verifica si las fechas estan en los plazos cubiertos 
		 		IF (:NEW.FECHA_INICIO >= PACK_PERS_TRAT.T_TRATAMIENTOS(v_contador).F_INICIO
		 		AND :NEW.FECHA_INICIO <= PKG_TRATAMIENTO.F_CALCULAR_FIN(:NEW.ID_TRATAMIENTO)) 
		 		OR (:NEW.FECHA_FIN IS NOT NULL AND 
		 		:NEW.FECHA_FIN >= PACK_PERS_TRAT.T_TRATAMIENTOS(v_contador).F_INICIO
		 		AND :NEW.FECHA_FIN <= PKG_TRATAMIENTO.F_CALCULAR_FIN(:NEW.ID_TRATAMIENTO)) 
		 		THEN
		 			-- verifica si es el mismo horario 
					IF :NEW.NRO_TURNO = PACK_PERS_TRAT.T_TRATAMIENTOS(v_contador).TURNO THEN 
						RAISE_APPLICATION_ERROR (-20002, '(!!!) El doctor o paciente estan ocupados ese dia en ese turno '); 
					END IF; 
		 		END IF;
		 	END IF; 
		 	v_contador :=  PACK_PERS_TRAT.T_TRATAMIENTOS.NEXT(v_contador);
		 END LOOP; 
	END; 
	
-------------------------------------------------------------------------------------------
-- TEMA 4 
-------------------------------------------------------------------------------------------

	CREATE OR REPLACE FUNCTION F_PACIENTE_ASIGNADO(P_TURNO NUMBER, P_ID_FISIO NUMBER) RETURN VARCHAR2 IS 
		V_NOMBRE_PAC VARCHAR2(50); 
	BEGIN 
		SELECT NOMBRE || ' ' || APELLIDO  
		INTO V_NOMBRE_PAC 
		FROM TRATAMIENTO T
		JOIN PACIENTE P ON P.CEDULA = T.CEDULA 
		WHERE T.COD_FISIOTERAPEUTA = P_ID_FISIO  AND T.NRO_TURNO = P_TURNO
			-- deberia ser "sysdate" para ver el calendario del dia pero puse para ver segun los datos disponibles xd 
		AND FECHA_INICIO <= to_date('07/06/2019', 'DD/MM/YYYY') AND F_CALCULAR_FIN(ID_TRATAMIENTO) > to_date('07/06/2019', 'DD/MM/YYYY') ; 
	
		RETURN V_NOMBRE_PAC; 
	END;
	
	-- crear la vista 
	CREATE MATERIALIZED VIEW V_HORARIO
	REFRESH START WITH SYSDATE 
	NEXT SYSDATE + 6/24 
	AS 
	SELECT F.APELLIDO || ' ' || F.NOMBRE FISIOTERAPEUTA,
	F_PACIENTE_ASIGNADO(1, F.COD_FISIOTERAPEUTA) "7:00",
	F_PACIENTE_ASIGNADO(2, F.COD_FISIOTERAPEUTA) "8:00", 
	F_PACIENTE_ASIGNADO(3, F.COD_FISIOTERAPEUTA) "9:00", 
	F_PACIENTE_ASIGNADO(4, F.COD_FISIOTERAPEUTA) "10:00", 
	F_PACIENTE_ASIGNADO(5, F.COD_FISIOTERAPEUTA) "11:00", 
	F_PACIENTE_ASIGNADO(6, F.COD_FISIOTERAPEUTA) "12:00", 
	F_PACIENTE_ASIGNADO(7, F.COD_FISIOTERAPEUTA) "13:00", 
	F_PACIENTE_ASIGNADO(8, F.COD_FISIOTERAPEUTA) "14:00", 
	F_PACIENTE_ASIGNADO(9, F.COD_FISIOTERAPEUTA) "15:00", 
	F_PACIENTE_ASIGNADO(10, F.COD_FISIOTERAPEUTA) "16:00", 
	F_PACIENTE_ASIGNADO(11, F.COD_FISIOTERAPEUTA) "17:00",
	F_PACIENTE_ASIGNADO(12, F.COD_FISIOTERAPEUTA) "18:00"
	FROM FISIOTERAPEUTA F
		
	-- consultar la vista 
	SELECT * FROM V_HORARIO; 
		
-------------------------------------------------------------------------------------------
-- TEMA 5 
-------------------------------------------------------------------------------------------

/* El procedimiento aceptara solo estos parametros: 
 * En criterio: 
 * 	- P paciente 
 * 	- M medico 
 * En ordenar por: 
 * 	- T por id_tratamiento 
 * 	- D por descripcion 
 * Se validaron los casos en los que se reciben otros parametros 
 * */

CREATE OR REPLACE PROCEDURE P_CONSULTAR_TRATAMIENTO 
	(P_CRITERIO VARCHAR2, P_ORDEN VARCHAR2, P_VALOR VARCHAR2)
IS  
	V_CRIT VARCHAR2(30);
	V_ORD VARCHAR2(30); 
	V_SQL VARCHAR2(800); 
BEGIN
	-- definir el sql para el criterio  
	IF P_CRITERIO = 'P' THEN
		V_CRIT := 'P.NOMBRE '; 
	ELsiF P_CRITERIO = 'M' THEN 
		V_CRIT := 'F.NOMBRE ';
	ELSE 
		RAISE_APPLICATION_ERROR (-20001, '(!!!) El parametro introducido para el criterio es invalido 
		Introducir P (nombre del paciente) o M (Nombre del medico)'); 
	END IF; 

	-- definir el sql para el orden 
	IF P_ORDEN = 'T' THEN
		V_ORD := 'T.ID_TRATAMIENTO '; 
	ELSIF P_ORDEN = 'D' THEN 
		V_ORD := 'T.DESCRIPCION ';
	ELSE 
		RAISE_APPLICATION_ERROR (-20002, '(!!!) El parametro introducido  para el orden es invalido. 
		Introducir T (id_tratamiento) o D (descripcion)'); 
	END IF; 
		
	-- definir la sentencia completa 
	V_SQL := '
	SELECT T.ID_TRATAMIENTO, T.DESCRIPCION, T.NRO_SESIONES, P.NOMBRE || '' '' || P.APELLIDO PACIENTE,  
	F.NOMBRE || '' '' || F.APELLIDO MEDICO, count(e.id_tratamiento) "CANT EQUIPOS"
	FROM TRATAMIENTO T
	JOIN FISIOTERAPEUTA F ON F.COD_FISIOTERAPEUTA = T.COD_FISIOTERAPEUTA 
	JOIN PACIENTE P ON P.CEDULA = T.CEDULA 
	JOIN EQUIPAMIENTO_UTILIZADO E ON E.ID_TRATAMIENTO  = T.ID_TRATAMIENTO 

	WHERE ' || V_CRIT || ' LIKE ''' || P_VALOR || '%''  
	GROUP BY T.ID_TRATAMIENTO, T.DESCRIPCION, T.NRO_SESIONES, P.NOMBRE, P.APELLIDO,  F.NOMBRE, F.APELLIDO 
	ORDER BY ' || V_ORD; 
	
	-- ejecutar 
	EXECUTE IMMEDIATE V_SQL;

	-- mostrar el codigo generado
	DBMS_OUTPUT.PUT_LINE('Codigo generado:'||V_SQL);
END; 

-- Probar el codigo 
BEGIN 
	P_CONSULTAR_TRATAMIENTO('M', 'T', 'MI'); 
END; 


