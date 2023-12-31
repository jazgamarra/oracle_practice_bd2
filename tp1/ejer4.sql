UPDATE D_PRODUCTOS dp
SET (dp.FECHA_ULTIMA_COMPRA, dp.PRECIO_ULTIMA_COMPRA) = (
	SELECT MAX(dmo.FECHA_OPERACION), MAX(ddo.PRECIO_OPERACION)
	FROM D_MOVIMIENTO_OPERACIONES dmo
	INNER JOIN D_DETALLE_OPERACIONES ddo ON dmo.ID_OPERACION = ddo.ID_OPERACION
	WHERE dmo.COD_OPERACION = 2
	AND dmo.ESTADO = 'A'	
	AND ddo.ID_PRODUCTO = dp.ID_PRODUCTO
	GROUP BY ddo.ID_PRODUCTO
);
