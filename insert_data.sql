SET datestyle TO 'DMY';

COPY proveedor (id, cuit, razon_social, tipo_sociedad, direccion, activo, habilitado)
FROM 'C:/Ian/ITBA/3er anio/bd-consigna-tp/proveedor.csv'
DELIMITER ';' CSV HEADER;

COPY producto (id, descripcion, marca, categoria, precio, stock)
FROM 'C:/Ian/ITBA/3er anio/bd-consigna-tp/producto.csv'
DELIMITER ';' CSV HEADER;

COPY orden_pedido (id, id_proveedor, fecha)
FROM 'C:/Ian/ITBA/3er anio/bd-consigna-tp/orden_pedido.csv'
DELIMITER ';' CSV HEADER;

COPY detalle_orden_pedido(id_pedido, nro_item, id_producto, cantidad)
FROM 'C:/Ian/ITBA/3er anio/bd-consigna-tp/detalle_orden_pedido.csv'
DELIMITER ';' CSV HEADER;