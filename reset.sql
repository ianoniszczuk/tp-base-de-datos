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

\echo '*** Proceso de reseteo completado. ***'