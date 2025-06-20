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
    FOREIGN KEY (id_pedido) REFERENCES orden_pedido(id), 
    FOREIGN KEY (id_producto) REFERENCES producto(id)
);

