-- 1. BORRAR TODO EL ESQUEMA 'public'
-- Esto elimina todas las tablas, funciones, triggers, etc. de una sola vez.
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- 2. RECREAR LAS TABLAS
\echo 'Creando tablas desde init.sql...'
\i 'C:/Ian/ITBA/3er anio/tp-base-de-datos/init.sql'

-- 3. RECREAR LOS TRIGGERS
\echo 'Creando triggers desde trigger.sql...'
\i 'C:/Ian/ITBA/3er anio/tp-base-de-datos/trigger.sql'

-- 4. INSERTAR LOS DATOS DE PRUEBA

\echo 'Insertando datos...'

\i 'C:/Ian/ITBA/3er anio/tp-base-de-datos/insert_data.sql'

-- 5. RECREAR LAS VISTAS

\echo 'Creando vistas desde create_view.sql...'
\i 'C:/Ian/ITBA/3er anio/tp-base-de-datos/create_view.sql'


-- 6. RECREAR EL TRIGGER PARA LA VISTA

\echo 'Creando trigger para la vista desde trigger2.sql...'
\i 'C:/Ian/ITBA/3er anio/tp-base-de-datos/trigger2.sql'

\echo '*** Proceso de reseteo completado. ***'

INSERT INTO orden_mes_categoria values ('2024-05','food',2,20,500);
INSERT INTO orden_mes_categoria values ('2024-05','food',1,50,200);

INSERT INTO orden_mes_categoria values ('2024-05','fish',2,3,300);

 delete from orden_mes_categoria where "Mes" = '2024-05' and "Categoria" ='food';