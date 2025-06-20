DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TABLE proveedor (
    id INT PRIMARY KEY,
    cuit BIGINT UNIQUE NOT NULL DEFAULT 0, 
    razon_social VARCHAR(100) DEFAULT 'No Asignada',
    tipo_sociedad VARCHAR(10) CHECK (tipo_sociedad IN ('SA', 'SRL', 'SAS', 'Colectiva')),
    direccion VARCHAR(255),
    activo SMALLINT DEFAULT 0 CHECK (activo IN (0, 1)),
    habilitado SMALLINT DEFAULT  0 CHECK (habilitado IN (0, 1))
);

CREATE TABLE producto (
    id INT PRIMARY KEY,
    descripcion VARCHAR(100),
    marca VARCHAR(50),
    categoria VARCHAR(50),
    precio DECIMAL(10, 2),
    stock INT 
);

CREATE TABLE orden_pedido (
    id INT PRIMARY KEY,
    id_proveedor INT,
    fecha DATE,
    monto DECIMAL(10, 2),
    FOREIGN KEY (id_proveedor) REFERENCES proveedor(id)
);

CREATE TABLE detalle_orden_pedido(
    id_pedido INT,
    nro_item INT,
    id_producto INT,
    cantidad INT,
    precio DECIMAL(10, 2),
    monto DECIMAL(10, 2),
    PRIMARY KEY (id_pedido, nro_item),
    FOREIGN KEY (id_pedido) REFERENCES orden_pedido(id) ON DELETE CASCADE, 
    FOREIGN KEY (id_producto) REFERENCES producto(id)
);

CREATE OR REPLACE FUNCTION registrar_insercion()
RETURNS TRIGGER AS $$
DECLARE
    -- Declarar la variable para almacenar los datos del producto
    producto_existente RECORD;
BEGIN

    IF NEW.cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad del producto debe ser mayor que cero. Se recibió: %', NEW.cantidad;
    END IF;

    -- Validar que el producto exista y obtener sus datos
    SELECT * INTO producto_existente FROM producto WHERE id = NEW.id_producto;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El producto con ID % no existe. No se puede agregar a la orden.', NEW.id_producto;
    END IF;

    NEW.precio := (SELECT precio FROM producto WHERE id = NEW.id_producto);
    -- 2. Calcular el monto para la nueva línea de detalle.
    NEW.monto := NEW.cantidad * NEW.precio;

    -- 3. Actualizar el stock del producto.
    UPDATE producto
    SET stock = stock + NEW.cantidad
    WHERE id = NEW.id_producto;

    -- 4. Actualizar el monto total en la orden de pedido (de forma eficiente).
    UPDATE orden_pedido
    SET monto = COALESCE(monto, 0) + NEW.monto
    WHERE id = NEW.id_pedido;

    -- 5. Devolver la fila modificada para que sea insertada.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- El trigger debe ser BEFORE para poder modificar la fila (NEW).
CREATE TRIGGER trigger_registrar_insercion
BEFORE INSERT ON detalle_orden_pedido
FOR EACH ROW
EXECUTE FUNCTION registrar_insercion();

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
    CAST(AVG(dop.monto) AS NUMERIC(10, 2)) AS "$_promedio"
FROM 
    orden_pedido op 
JOIN 
    detalle_orden_pedido dop ON op.id = dop.id_pedido
JOIN
    producto p ON dop.id_producto = p.id
WHERE 
    EXTRACT(YEAR FROM op.fecha) = (SELECT EXTRACT(YEAR FROM MAX(fecha)) FROM orden_pedido)
GROUP BY
    "Mes", "Categoria";

    
CREATE OR REPLACE FUNCTION insert_to_view()
RETURNS TRIGGER AS $$
DECLARE 
    v_proveedor_id INT;
    v_producto_id INT;
    v_cantidad_por_orden_min INT;
    v_cantidad_por_orden INT;
    v_fecha_orden DATE;
    v_orden_id INT;   
    v_precio_aux DECIMAL(10, 2);
    v_precio DECIMAL(10, 2);
    v_max_year INT;
BEGIN 

    IF NEW."Total_cantidad" < NEW."#_ordenes" THEN
            RAISE EXCEPTION 'La cantidad total (%) es mas pequeña que la cant de ordenes (%).', 
                            NEW."Total_cantidad", NEW."#_ordenes";
    END IF;

    IF NEW."#_ordenes" <= 0 THEN
        RAISE EXCEPTION 'El número de órdenes debe ser mayor que cero. Se recibió: %', NEW."#_ordenes";
    END IF;  

    SELECT MAX(EXTRACT(YEAR FROM fecha)) INTO v_max_year FROM orden_pedido;

    IF EXTRACT(YEAR FROM TO_DATE(NEW."Mes" || '-01', 'YYYY-MM-DD')) < v_max_year THEN
        RAISE EXCEPTION 'El anio (%s) no puede ser anterior al anio mas reciente (%s).', 
                       EXTRACT( YEAR FROM TO_DATE(NEW."Mes" || '-01', 'YYYY-MM-DD')), v_max_year;
    END IF;

     IF EXISTS (
        SELECT 1 
        FROM proveedor 
        WHERE razon_social = 'No Asignada'
    ) THEN
        v_proveedor_id = (SELECT id FROM proveedor WHERE razon_social = 'No Asignada');
    ELSE
        v_proveedor_id := (SELECT COALESCE(MAX(id), 0) + 1 FROM proveedor);
        INSERT INTO proveedor (id)
        VALUES (v_proveedor_id);
    END IF;

    v_cantidad_por_orden_min= (NEW."Total_cantidad" - (NEW."Total_cantidad" % NEW."#_ordenes")) / NEW."#_ordenes";

    IF EXISTS (
        SELECT 1 
        FROM ORDEN_MES_CATEGORIA 
        WHERE "Mes" = NEW."Mes" 
          AND "Categoria" = NEW."Categoria"
    ) THEN

        v_producto_id = (SELECT id FROM producto WHERE descripcion = 'No Asignado - ' || NEW."Categoria");
    ELSE 
        v_producto_id := (SELECT COALESCE(MAX(id), 0) + 1 FROM producto);

        v_precio := NEW."$_promedio" * NEW."#_ordenes" / NEW."Total_cantidad"; 

        INSERT INTO producto (id, descripcion, marca, categoria, precio, stock)
        VALUES (v_producto_id, 'No Asignado - ' || NEW."Categoria", 'NA', NEW."Categoria", v_precio , 0);
    END IF;  

    v_fecha_orden := TO_DATE(NEW."Mes" || '-01', 'YYYY-MM-DD');

    FOR i IN 1..NEW."#_ordenes" LOOP
        v_orden_id := (SELECT COALESCE(MAX(id), 0) + 1 FROM orden_pedido);

        IF i <= (NEW."Total_cantidad" % NEW."#_ordenes") THEN 
            v_cantidad_por_orden := v_cantidad_por_orden_min + 1;
        ELSE
            v_cantidad_por_orden := v_cantidad_por_orden_min;
        END IF;

        INSERT INTO orden_pedido (id, id_proveedor, fecha)
        VALUES (v_orden_id, v_proveedor_id, v_fecha_orden);

        INSERT INTO detalle_orden_pedido (id_pedido, nro_item, id_producto, cantidad)
        VALUES (v_orden_id, 1, v_producto_id, v_cantidad_por_orden);

    END LOOP;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql; 

CREATE TRIGGER trigger_insert_to_view
INSTEAD OF INSERT ON ORDEN_MES_CATEGORIA
FOR EACH ROW
EXECUTE FUNCTION insert_to_view();

CREATE OR REPLACE FUNCTION delete_from_view()
RETURNS TRIGGER AS $$
DECLARE
v_producto_id INT;
    v_orden_id INT;
    id_eliminar INT;
    stock_sacar INT;
BEGIN
    RAISE NOTICE 'Borrando órdenes para el mes % y categoría %', OLD."Mes", OLD."Categoria";

    -- Usamos un bucle para iterar sobre todas las órdenes que coinciden con los criterios.
    -- OLD."Mes" y OLD."Categoria" contienen los valores de la fila que se intenta borrar.
        v_producto_id = (SELECT id FROM producto WHERE descripcion = 'No Asignado - ' || OLD."Categoria");
        -- Primero, borramos los detalles de la orden para evitar errores de clave foránea.
        FOR v_orden_id IN 
        SELECT DISTINCT dop.id_pedido
        FROM detalle_orden_pedido dop
        JOIN orden_pedido op ON dop.id_pedido = op.id
        WHERE dop.id_producto = v_producto_id
          AND TO_CHAR(op.fecha, 'YYYY-MM') = OLD."Mes"  -- FILTRO POR MES
    LOOP

  DELETE FROM detalle_orden_pedido 
        WHERE id_pedido = v_orden_id AND id_producto = v_producto_id
        RETURNING id_pedido, cantidad INTO id_eliminar, stock_sacar;   
                 -- Luego, borramos la orden principal.
            UPDATE producto
            SET stock = stock - stock_sacar
            WHERE id = v_producto_id;

            DELETE FROM orden_pedido WHERE id = id_eliminar;
        END LOOP;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Creamos el nuevo trigger que se activa con DELETE
CREATE TRIGGER trigger_delete_from_view
INSTEAD OF DELETE ON ORDEN_MES_CATEGORIA
FOR EACH ROW
EXECUTE FUNCTION delete_from_view();