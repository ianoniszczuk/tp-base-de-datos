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