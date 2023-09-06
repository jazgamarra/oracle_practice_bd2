/*
Obtenga la lista de empleados con su posición y salario vigente (El salario y la categoría
vigente tienen la fecha fin nula – Un solo salario está vigente en un momento dado). Debe
listar:
Nombre área, Apellido y nombre del empleado, Fecha Ingreso, categoría, salario actual
La lista debe ir ordenada por nombre de área, y por apellido del funcionario.
*/

SELECT AR.NOMBRE_AREA AS AREA, EM.NOMBRE || ' ' || EM.APELLIDO AS NOMBRE_COMPLETO, EM.FECHA_ING, CAT.NOMBRE_CAT, CAT.ASIGNACION
FROM B_EMPLEADOS EM
JOIN B_POSICION_ACTUAL PAC ON EM.CEDULA = PAC.CEDULA
JOIN B_CATEGORIAS_SALARIALES CAT ON CAT.COD_CATEGORIA = PAC.COD_CATEGORIA
JOIN B_AREAS AR ON AR.ID = PAC.ID_AREA
ORDER BY AREA, APELLIDO;

/*
Se necesita tener la lista completa de personas (independientemente de su tipo), ordenando
por nombre de localidad. Si la persona no tiene asignada una localidad, también debe
aparecer. Liste Nombre de Localidad, Nombre y apellido de la persona, dirección, teléfono
*/

SELECT LO.NOMBRE AS NOMBRE_LOC, PE.NOMBRE || ' ' || PE.APELLIDO AS NOMBRE_COMPLETO, PE.DIRECCION, PE.TELEFONO
FROM B_PERSONAS PE
JOIN B_LOCALIDAD LO ON LO.ID = PE.ID_LOCALIDAD
ORDER BY LO.NOMBRE;

/*
En base a la consulta anterior, liste todas las localidades, independientemente que existan
personas en dicha localidad:
*/

SELECT NOMBRE FROM B_LOCALIDAD ORDER BY NOMBRE;

/*
Obtenga la misma lista del ejercicio 3, pero asegurándose de listar todas las personas,
independientemente que estén asociadas a una localidad, y todas las localidades, aún cuando
no tengan personas asociadas.
*/

SELECT LO.NOMBRE AS NOMBRE_LOC, PE.NOMBRE || ' ' || PE.APELLIDO AS NOMBRE_COMPLETO, PE.DIRECCION, PE.TELEFONO
FROM B_PERSONAS PE
FULL OUTER JOIN B_LOCALIDAD LO ON LO.ID = PE.ID_LOCALIDAD
ORDER BY LO.NOMBRE, NOMBRE_COMPLETO;

/*
La organización ha decidido mantener un registro único de todas las personas, sean éstas
proveedores, clientes y/o empleados. Para el efecto se le pide una operación de UNION entre
las tablas de B_PERSONAS y B_EMPLEADOS. Debe listar
CEDULA, APELLIDO, NOMBRE, DIRECCION, TELEFONO, FECHA_NACIMIENTO.
En la tabla PERSONAS tenga únicamente en cuenta las personas de tipo FISICAS (F) y
que tengan cédula. Ordene la consulta por apellido y nombre
 */

SELECT TO_NUMBER(CEDULA), APELLIDO, NOMBRE, DIRECCION, TELEFONO, FECHA_NACIMIENTO FROM B_PERSONAS
WHERE TIPO_PERSONA = 'F' AND CEDULA IS NOT NULL
UNION
SELECT CEDULA, APELLIDO, NOMBRE, DIRECCION, TELEFONO, FECHA_NACIM FROM B_EMPLEADOS BE
ORDER BY APELLIDO, NOMBRE;

/*
Liste el libro DIARIO correspondiente al año 2019, tomando en cuenta la cabecera y el
detalle. Debe listar los siguientes datos:
ID_Asiento, Fecha, Concepto, Nro.Linea, código cuenta, nombre cuenta, debe_haber,
Importe (para obtener el año puede usar LIKE).
*/

SELECT DCA.ID AS ID_ASIENTO, DCA.FECHA, DCA.CONCEPTO, DDE.NRO_LINEA, DDE.CODIGO_CTA, DDE.DEBE_HABER, DDE.IMPORTE
FROM B_DIARIO_CABECERA DCA
JOIN B_DIARIO_DETALLE DDE ON DCA.ID = DDE.ID
WHERE EXTRACT(YEAR FROM DCA.FECHA) = 2019;

/* 
Transforme el ejercicio 7 para que obtenga los asientos de ENERO del 2019, condicionado al
campo DEBE_HABER , imprima el importe en la columna DEBITO o en la columna
CREDITO.
ID_Asiento, Fecha, Concepto, Nro.Linea, código cuenta, nombre cuenta, DEBITO,
CREDITO 
*/      

SELECT DCA.ID AS ID_ASIENTO, DCA.FECHA, DCA.CONCEPTO, DDE.NRO_LINEA, DDE.CODIGO_CTA,
    CASE  DDE.DEBE_HABER 
        WHEN 'C' THEN DDE.IMPORTE
        WHEN 'D' THEN 0
    END CREDITO, 
    CASE  DDE.DEBE_HABER 
        WHEN 'C' THEN 0
        WHEN 'D' THEN DDE.IMPORTE 
    END DEBITO	
FROM B_DIARIO_CABECERA DCA 
JOIN B_DIARIO_DETALLE DDE ON DCA.ID = DDE.ID  
WHERE EXTRACT(YEAR FROM DCA.FECHA) = 2019; 

/*
El campo FILE_NAME del archivo DBA_DATA_FILES contiene el nombre y camino de
los archivos físicos que conforman los espacios de tabla de la Base de Datos. Seleccione:
-Solamente el nombre del archivo (sin mencionar la carpeta o camino):
*/ 
SELECT SUBSTR(FILE_NAME, INSTR(FILE_NAME, '\', -1) + 1) AS NOMBRE_ARCHIVOS
FROM DBA_DATA_FILES
-- instr busca el caracter '\' desde el final (porque el parametro es -1)

/*    
Se pretende realizar el aumento salarial del 5% para todas las categorías. Debe listar la
categoría (código y nombre), el importe actual, el importe aumentado al 5% (redondeando la
cifra a la centena), y la diferencia.
*/
SELECT COD_CATEGORIA, ASIGNACION, ASIGNACION + ASIGNACION * 0.05, ASIGNACION * 0.05
FROM B_CATEGORIAS_SALARIALES bcs; 

/*
Considerando la fecha de hoy, indique cuándo caerá el próximo DOMINGO.
*/
SELECT NEXT_DAY(SYSDATE, 'Domingo') FROM dual; 
SELECT NEXT_DAY(SYSDATE, 1) FROM dual; 

/*
Utilice la función LAST_DAY para determinar si este año es bisiesto o no. Con CASE y con
DECODE, haga aparecer la expresión ‘bisiesto’ o ‘no bisiesto’ según corresponda.
*/
-- el ultimo dia de febrero (tipo date)
SELECT LAST_DAY(TO_DATE('01-FEB-2023', 'DD-MON-YYYY')) FROM dual; 

-- extraer el numero de dia de esa fecha 
SELECT EXTRACT(DAY FROM LAST_DAY(TO_DATE('01-FEB-2023', 'DD-MON-YYYY'))) FROM dual; 

-- ahora si 
SELECT 
CASE EXTRACT(DAY FROM LAST_DAY(TO_DATE('01-FEB-2020', 'DD-MON-YYYY'))) 
    WHEN 28 THEN 'No bisiesto'
    WHEN 29 THEN 'Bisiesto'
END AS es_bisiesto
FROM DUAL; 

/*
Tomando en cuenta la fecha de hoy, verifique que fecha dará redondeando al año? Y
truncando al año? Escriba el resultado. Pruebe lo mismo suponiendo que sea el 1 de Julio del
año. Pruebe también el 12 de marzo.
*/
SELECT 
    ROUND(SYSDATE, 'year') AS r_sysdate,     
    TRUNC(SYSDATE, 'year') AS t_sysdate, 
    ROUND(TO_DATE('01-JUL-2023', 'DD-MON-YYYY'), 'year') AS r_july, 
    TRUNC(TO_DATE('01-JUL-2023', 'DD-MON-YYYY'), 'year') AS t_july
FROM dual;

/*
Imprima su edad en años y meses. Ejemplo: Si nació el 23/abril/1972, tendría 43 años y 3
meses a la fecha
*/
SELECT EXTRACT(YEAR FROM sysdate) - EXTRACT(YEAR FROM(to_date('10/03/2003', 'DD/MM/YY'))) AS ANHOS,
EXTRACT(MONTH FROM sysdate) - EXTRACT(MONTH FROM(to_date('10/03/2003', 'DD/MM/YY'))) AS MESES 
FROM DUAL; 
 
/*
Liste ID y NOMBRE de todos los artículos que no están incluidos en ninguna VENTA. Debe
utilizar necesariamente la sentencia MINUS.
 */
SELECT ID, NOMBRE FROM B_ARTICULOS AR 
    MINUS 
SELECT ID_ARTICULO, NOMBRE FROM B_DETALLE_VENTAS 
JOIN B_ARTICULOS AR ON AR.ID = ID_ARTICULO; 

/*
El área de CREDITOS Y COBRANZAS solicita un informe de las ventas a crédito
efectuadas en el año 2018 y cuyas cuotas tienen atraso en el pago. A las cuotas que se
encuentran en dicha situación se le aplica una tasa de interés del 0.5% por cada día de atraso.
Se considera que una cuota está en mora cuando ya pasó la fecha de vencimiento y no existe
aún pago alguno. Se pide mostrar los siguientes datos y ordenar de forma descendente por
días de atraso.
*/
SELECT VEN.NUMERO_FACTURA AS NRO_FACTURA, EMP.NOMBRE || ' ' || EMP.APELLIDO AS VENDEDOR, 
PER.RUC, PER.NOMBRE || ' ' || PER.APELLIDO AS CLIENTE, PLP.NUMERO_CUOTA AS NRO_CUOTA, 
PLP.VENCIMIENTO,  PLP.MONTO_CUOTA, TRUNC(SYSDATE) - PLP.VENCIMIENTO AS DIAS_ATRASO, 
(TRUNC(SYSDATE) - PLP.VENCIMIENTO) * PLP.MONTO_CUOTA * 0.05 AS INTERES, 
(TRUNC(SYSDATE) - PLP.VENCIMIENTO) * PLP.MONTO_CUOTA * 0.05 + PLP.MONTO_CUOTA AS MONTO_PAGAR
FROM B_VENTAS VEN
	JOIN B_EMPLEADOS EMP ON EMP.CEDULA = VEN.CEDULA_VENDEDOR 
	JOIN B_PERSONAS PER ON PER.ID = VEN.ID_CLIENTE 
	JOIN B_PLAN_PAGO PLP ON PLP.ID_VENTA = VEN.ID 
WHERE TIPO_VENTA = 'CR' 
	AND EXTRACT(YEAR FROM VEN.FECHA) = 2018
ORDER BY DIAS_ATRASO DESC 

/*
El Dpto. Financiero de la empresa necesita un informe de los movimientos correspondientes a
compras y ventas efectuadas en el primer semestre del año 2018.
El informe debe contener:
 Fecha de la operación.
 Concepto: Para obtener esta columna debe concatenar las expresiones y/o campos:
 Operación: Venta o Compra de mercaderías según factura.
 Tipo de Factura: Contado o Crédito.
 Factura
 Monto Débito: Si es una compra se coloca el monto de la operación, pero si es una venta
se coloca 0.
 Monto Crédito: Si es una venta se coloca el monto de la operación, pero si es una compra
se coloca 0.
Por último, se pide que ordene los registros por la fecha en forma ascendente
 */
SELECT FECHA, 'VENTA DE MERCADERIAS A ' || 
CASE TIPO_VENTA 
	WHEN 'CO' THEN 'CONTADO'
	WHEN 'CR' THEN 'CREDITO'
END 
|| ' SEGUN FACTURA Nro. ' || NUMERO_FACTURA AS CONCEPTO, 
0 AS MONTO_DEBITO, MONTO_TOTAL  AS MONTO_CREDITO
FROM B_VENTAS
UNION 
SELECT FECHA, 'COMPRA DE MERCADERIAS', 
MONTO_TOTAL AS MONTO_DEBITO, 0 AS MONTO_CREDITO
FROM B_COMPRAS 
ORDER BY FECHA DESC; 