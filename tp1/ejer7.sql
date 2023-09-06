CREATE MATERIALIZED VIEW INFORME_CIERRE_DIARIO
	REFRESH COMPLETE
	NEXT TRUNC(SYSDATE) + INTERVAL '20' HOUR
	WITH PRIMARY KEY
AS SELECT FPA.DESC_FORMA_PAGO AS descripcion,
	SUM(CASE WHEN MOV.NRO_CAJA = 1 THEN POP.IMPORTE_PAGO ELSE 0 END) AS CAJA_1,
	SUM(CASE WHEN MOV.NRO_CAJA = 2 THEN POP.IMPORTE_PAGO ELSE 0 END) AS CAJA_2,
	SUM(CASE WHEN MOV.NRO_CAJA = 3 THEN POP.IMPORTE_PAGO ELSE 0 END) AS CAJA_3,
	SUM(CASE WHEN MOV.NRO_CAJA = 4 THEN POP.IMPORTE_PAGO ELSE 0 END) AS CAJA_4
FROM D_MOVIMIENTO_OPERACIONES MOV
JOIN D_PAGO_OPERACION POP ON POP.ID_OPERACION = MOV.ID_OPERACION
JOIN D_FORMA_PAGO FPA ON FPA.COD_FORMA_PAGO = POP.COD_FORMA_PAGO
GROUP BY FPA.DESC_FORMA_PAGO
UNION
SELECT 'TOTAL',
	SUM(CASE WHEN MOV.NRO_CAJA = 1 THEN POP.IMPORTE_PAGO ELSE 0 END) AS CAJA_1,
	SUM(CASE WHEN MOV.NRO_CAJA = 2 THEN POP.IMPORTE_PAGO ELSE 0 END) AS CAJA_2,
	SUM(CASE WHEN MOV.NRO_CAJA = 3 THEN POP.IMPORTE_PAGO ELSE 0 END) AS CAJA_3,
	SUM(CASE WHEN MOV.NRO_CAJA = 4 THEN POP.IMPORTE_PAGO ELSE 0 END) AS CAJA_4
FROM D_MOVIMIENTO_OPERACIONES MOV
JOIN D_PAGO_OPERACION POP ON POP.ID_OPERACION = MOV.ID_OPERACION
JOIN D_FORMA_PAGO FPA ON FPA.COD_FORMA_PAGO = POP.COD_FORMA_PAGO;