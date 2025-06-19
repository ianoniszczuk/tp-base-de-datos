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
    SELECT * INTO producto_existente FROM producto WHERE id = NEW.id_product;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El producto con ID % no existe. No se puede agregar a la orden.', NEW.id_product;
    END IF;

    -- Validar que haya stock suficiente
    -- 1. Asignar el precio del producto si no viene especificado.
    --    Se usa `:=` para la asignación, que es la sintaxis estándar en PL/pgSQL.
    IF NEW.precio IS NULL THEN
        NEW.precio := (SELECT precio FROM producto WHERE id = NEW.id_product);
    END IF;

    -- 2. Calcular el monto para la nueva línea de detalle.
    NEW.monto := NEW.cantidad * NEW.precio;

    -- 3. Actualizar el stock del producto.
    UPDATE producto
    SET stock = stock + NEW.cantidad
    WHERE id = NEW.id_product;

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