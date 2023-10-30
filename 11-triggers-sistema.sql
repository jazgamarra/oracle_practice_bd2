
/*
Para crear los siguientes triggers, debe tener el privilegio ADMINISTER DATABASE TRIGGER
1. Cree la tabla log_conexiones que tenga los siguientes campos:
Usuario
Fecha
Operacion (LOGON o LOGOFF)
Cree un trigger que se dispare DESPUES que un usuario haga logon en el sistema. El trigger deberá
guardar el id del usuario y la fecha. Con ello se podrá saber todos los usuarios que ingresaron y en que
momento. Cree otro trigger que sea ANTES del logoff y que grabe la misma información
*/

-- revisamos si tenemos el privilegio 
SELECT * FROM dba_sys_privs WHERE privilege LIKE 'ADMINISTER DATABASE TRIGGER'; 

-- crear la tabla 
CREATE TABLE LOG_CONEXIONES (
	USUARIO VARCHAR2(30), 
	FECHA DATE, 
	OPERACION VARCHAR(10)
);

-- crear el trigger para el login 
CREATE OR REPLACE TRIGGER ON_LOGON 
AFTER LOGON ON BASEDATOS2.Schema
BEGIN
	INSERT INTO LOG_CONEXIONES
	VALUES (ora_login_user, sysdate, 'Log-on');
END;

-- crear el trigger para el logoff  
CREATE OR REPLACE TRIGGER ON_LOGOFF 
BEFORE LOGOFF ON BASEDATOS2.Schema
BEGIN
	INSERT INTO LOG_CONEXIONES
	VALUES (ora_login_user, sysdate, 'Log-off');
END;

SELECT * FROM LOG_CONEXIONES; 
