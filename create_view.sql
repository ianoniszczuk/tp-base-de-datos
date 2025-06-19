CREATE OR REPLACE VIEW ORDEN_MES_CATEGORIA AS
SELECT 
   TO_CHAR(op.fecha, 'YYYY-MM') AS "Mes",
    
    -- Obtener la categoría del producto
    p.categoria AS "Categoria",
    
    -- Contar la cantidad de órdenes distintas
    COUNT(DISTINCT op.id) AS "#_ordenes",
    
    -- Sumar la cantidad total de productos pedidos
    SUM(dop.cantidad) AS "Total_cantidad",
    
    -- Calcular el promedio del monto de los detalles de la orden
    AVG(dop.monto) AS "$_promedio"
FROM 
    orden_pedido op 
JOIN 
    detalle_orden_pedido dop ON op.id = dop.id_pedido
JOIN
    producto p ON dop.id_product = p.id
WHERE 
    EXTRACT(YEAR FROM op.fecha) = (SELECT EXTRACT(YEAR FROM MAX(fecha)) FROM orden_pedido)
GROUP BY
    "Mes", "Categoria"