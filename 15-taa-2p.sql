---------------------------------------------------------------------------------------------------------
-- TEMA 1: Cree los siguientes elementos en la Base de Datos 
---------------------------------------------------------------------------------------------------------
/*
 1. El tipo TAB_EST como una tabla anidada de números
 */

	CREATE OR REPLACE TYPE TAB_EST AS TABLE OF NUMBER; 

/*
 2. El tipo TAB_PROF como un VARRAY de 3 elementos numéricos 
 */

	CREATE OR REPLACE TYPE TAB_PROF AS VARRAY(3) OF NUMBER; 

/*
3. El tipo T_EXAMEN como un objeto compuesto de los siguientes elementos (Especificación)
	• ID_CURSO NUMBER(8)
	• ID_ACTA NUMBER(8)
	• TIPO_EXAMEN VARCHAR2(2)
	• FECHA_EXAMEN DATE
	• MESA_EXAMINADORA TAB_PROF
	• ALUMNOS_HABILITADOS TAB_EST
Y los siguientes métodos:
	• El método miembro ASIGNAR_ALUMNOS como un procedimiento que asignará el atributo
		ALUMNOS_HABILITADOS
	• El método ORDER ORDENAR_ALUMNOS 
 */

	CREATE OR REPLACE TYPE T_EXAMEN AS OBJECT (
		ID_CURSO NUMBER(8),
		ID_ACTA NUMBER(8),
		TIPO_EXAMEN VARCHAR2(2),
		FECHA_EXAMEN DATE,
		MESA_EXAMINADORA TAB_PROF,
		ALUMNOS_HABILITADOS TAB_EST,
		MEMBER PROCEDURE ASIGNAR_ALUMNOS, 
		ORDER MEMBER FUNCTION ORDENAR_ALUMNOS (EXAMEN T_EXAMEN) RETURN NUMBER
	);

/*
 4. El BODY del tipo especificado en el ítem anterior deberá realizar lo siguiente:
	• El método miembro ASIGNAR_ALUMNOS deberá asignar el atributo ALUMNOS_HABILITADOS con todos
	los alumnos matriculados en el curso dado por el atributo ID_CURSO, cuya matrícula no esté finalizada y que
	estén al día (AL_DIA = ‘S’)
	• El método ORDENAR_ALUMNOS deberá considerar como criterio de ordenamiento el ID_ACTA.
 */

	CREATE OR REPLACE TYPE BODY T_EXAMEN AS 
	
		-- procedimiento para asignar alumnos 
		MEMBER PROCEDURE ASIGNAR_ALUMNOS IS 
			CURSOR C_ALUMNOS_MATRICULADOS IS 
				SELECT EST.CEDULA FROM ESTUDIANTES EST 
				JOIN MATRICULA MAT ON EST.CEDULA = MAT.CEDULA
				WHERE MAT.FECHA_FIN_MATRICULA > SYSDATE AND MAT.AL_DIA = 'S'; 
			
			V_CONTADOR NUMBER := 1; 
		BEGIN
			SELF.ALUMNOS_HABILITADOS := TAB_EST(); 
			
			FOR ALUMNO IN C_ALUMNOS_MATRICULADOS LOOP 
				SELF.ALUMNOS_HABILITADOS.EXTEND(); 
				SELF.ALUMNOS_HABILITADOS(V_CONTADOR) := ALUMNO.CEDULA; 
				V_CONTADOR := V_CONTADOR + 1; 
			END LOOP; 
		END;
	
		-- metodo de ordenamiento 
		ORDER MEMBER FUNCTION ORDENAR_ALUMNOS (EXAMEN T_EXAMEN) RETURN NUMBER IS
		  BEGIN
		    -- Comparamos los nombres compuestos de los clientes
		    IF self.ID_ACTA < EXAMEN.ID_ACTA THEN
		      RETURN -1;
		    ELSIF self.ID_ACTA = EXAMEN.ID_ACTA THEN
		      RETURN 0;
		    ELSE
		      RETURN 1;
		    END IF;
		  END;
	END; 

/*
 5. La tabla de base de datos ACTA_EXAMEN como una tabla de objetos de tipo T_EXAMEN
 */

	CREATE TABLE ACTA_EXAMEN OF T_EXAMEN
	NESTED TABLE ALUMNOS_HABILITADOS STORE AS HABILITADOS;

---------------------------------------------------------------------------------------------------------
-- TEMA 2: Programe el o los trigger(s) necesarios para implementar las siguientes reglas de negocio,
-- cada vez que se inserta o actualiza algún registro de la tabla ACTA_EXAMEN
---------------------------------------------------------------------------------------------------------

/*
 6. Debe impedir que se tenga más de un acta para un curso y tipo de examen (Puede haber actas del mismo
curso pero de diferentes tipos).
 */

CREATE OR REPLACE TRIGGER T_ACTAS_DUPLICADAS 
	BEFORE INSERT OR UPDATE ON ACTA_EXAMEN
	FOR EACH ROW
DECLARE
	V_CANT_ACTAS NUMBER := 0; 	
BEGIN 
		SELECT COUNT(*) INTO V_CANT_ACTAS
		FROM ACTA_EXAMEN
		WHERE ID_CURSO = :NEW.id_curso
		AND tipo_examen = :NEW.tipo_examen;
	
		IF V_CANT_ACTAS != 0 THEN 
			RAISE_APPLICATION_ERROR (-20001, '(!!!) No se pueden tener dos actas con el mismo tipo de examen para el mismo curso. '); 
		END IF; 
END; 

-- Probar el trigger 
INSERT INTO ACTA_EXAMEN (id_curso, id_acta, tipo_examen, fecha_examen) VALUES (1, 1, '1P', sysdate); 
INSERT INTO ACTA_EXAMEN (id_curso, id_acta, tipo_examen, fecha_examen) VALUES (1, 2, '1P', sysdate); -- genera error gracias al trigger

/* 
 7. Debe asignar el primer elemento del atributo MESA_EXAMINADORA con el identificador del profesor
del curso 
**/

CREATE OR REPLACE TRIGGER T_ASIGNAR_PROFE_CURSO 
	BEFORE INSERT OR UPDATE ON ACTA_EXAMEN
	FOR EACH ROW
DECLARE
	V_PROFE NUMBER; 
	v_contador NUMBER; 
	v_posicion NUMBER := -1; 
BEGIN		 	
	-- ver quien es el profe del curso 
	SELECT PROFESOR
	INTO V_PROFE 
	FROM MATERIA_SECCION 
	WHERE :NEW.ID_CURSO = ID_CURSO; 

	-- recorrer para ver si existe y en que pos. esta 
	v_contador := :NEW.MESA_EXAMINADORA.FIRST;
	WHILE v_contador <= :NEW.MESA_EXAMINADORA.LAST LOOP
		IF :NEW.MESA_EXAMINADORA(V_CONTADOR) = V_PROFE THEN 
			V_POSICION := V_CONTADOR; 
			EXIT WHEN V_POSICION != -1;
		END IF; 		
	 	v_contador := :NEW.MESA_EXAMINADORA.NEXT(v_contador);
	 END LOOP;
	
	-- si el profe no esta en la primera posicion, intercambiar con el de la primera posicion 
	IF v_posicion != -1 THEN 
		IF :NEW.MESA_EXAMINADORA(:NEW.MESA_EXAMINADORA.FIRST) != :NEW.MESA_EXAMINADORA(v_posicion) THEN 
			v_contador := :NEW.MESA_EXAMINADORA(v_posicion); 
			:NEW.MESA_EXAMINADORA(v_posicion) := :NEW.MESA_EXAMINADORA(:NEW.MESA_EXAMINADORA.FIRST); 
			:NEW.MESA_EXAMINADORA(:NEW.MESA_EXAMINADORA.FIRST) := v_contador; 
		END IF; 
	ELSE 
		:NEW.MESA_EXAMINADORA.extend(); 
		:NEW.MESA_EXAMINADORA(1) := v_profe; 
	END IF; 
END; 

/*
 8. Debe asignar el atributo ALUMNOS_HABILITADOS solamente usando el método ASIGNAR_ALUMNOS 
 */

CREATE OR REPLACE TRIGGER T_HABILITAR_ALUMNOS  
	BEFORE INSERT OR UPDATE ON ACTA_EXAMEN
	FOR EACH ROW 
DECLARE 
	temp_examen T_EXAMEN := T_EXAMEN(
      :NEW.ID_CURSO,
      :NEW.ID_ACTA,
      :NEW.TIPO_EXAMEN,
      :NEW.FECHA_EXAMEN,
      :NEW.MESA_EXAMINADORA,
      NULL -- No es necesario asignar ALUMNOS_HABILITADOS aquí
    );
BEGIN
	temp_examen.ASIGNAR_ALUMNOS(); 
    :NEW.ALUMNOS_HABILITADOS := temp_examen.alumnos_habilitados;
END;