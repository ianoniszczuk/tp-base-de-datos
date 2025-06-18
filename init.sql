CREATE TABLE proveedor (
    id INT PRIMARY KEY,
    cuit BIGINT UNIQUE NOT NULL, 
    razon_social VARCHAR(100),
    tipo_sociedad VARCHAR(10) CHECK (tipo_sociedad IN ('SA', 'SRL', 'SAS', 'Colectiva')),
    direccion VARCHAR(255),
    activo BOOLEAN NOT NULL,
    habilitado BOOLEAN NOT NULL
);

CREATE TABLE producto (
    id INT PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    stock INT NOT NULL,
);

CREATE TABLE orden_pedido (
    id INT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    fecha DATE NOT NULL,
    FOREIGN KEY (proveedor_id) REFERENCES proveedor(id)
);

CREATE TABLE detalle_orden_pedido (
    id_pedido INT NOT NULL,
    nro_item INT NOT NULL,
    id_product INT NOT NULL,
    cantidad INT NOT NULL,
    PRIMARY KEY (id_pedido, nro_item),
    FOREIGN KEY (id_pedido) REFERENCES orden_pedido(id),
    FOREING KEY (id_product) REFERENCES producto(id)
);