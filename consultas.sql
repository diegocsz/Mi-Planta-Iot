-- 1. Primero, crea las tablas (puedes ejecutar esto junto)
DROP TABLE IF EXISTS plantas;
DROP TABLE IF EXISTS tipos_planta;

CREATE TABLE tipos_planta (
    id_tipo_planta SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    temp_min NUMERIC(3,1),
    temp_max NUMERIC(3,1),
    hum_min NUMERIC(3,1),
    hum_max NUMERIC(3,1)
);

CREATE TABLE plantas (
    id_planta SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    nombre_duenio VARCHAR(50) NOT NULL,
    tipo_id INTEGER REFERENCES tipos_planta(id_tipo_planta),
    ultima_temp NUMERIC(3,1) DEFAULT 0,
    ultima_hum NUMERIC(3,1) DEFAULT 0
);

-- 2. Después, crea la función (esto suele requerir ir en un bloque aparte en la mayoría de gestores)
CREATE OR REPLACE FUNCTION obtener_estado_plantas()
RETURNS TABLE(nombre VARCHAR, alertas TEXT, estado_general TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.nombre,
        CONCAT_WS(' y ', 
            CASE WHEN p.ultima_hum < t.hum_min THEN 'Necesita Agua' ELSE NULL END,
            CASE WHEN p.ultima_temp < t.temp_min OR p.ultima_temp > t.temp_max THEN 'Necesita Luz/Ambiente' ELSE NULL END
        ),
        CASE 
            WHEN p.ultima_temp BETWEEN t.temp_min AND t.temp_max 
                 AND p.ultima_hum BETWEEN t.hum_min AND t.hum_max 
            THEN 'Perfectas condiciones'
            ELSE 'Requiere Atención'
        END
    FROM plantas p
    JOIN tipos_planta t ON p.tipo_id = t.id_tipo_planta; -- CORREGIDO: p.tipo_id
END;
$$ LANGUAGE plpgsql;