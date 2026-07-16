
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

SELECT * FROM plantas;
SELECT * FROM tipos_planta;

INSERT INTO tipos_planta (nombre, temp_min, temp_max, hum_min, hum_max) 
VALUES ('cactus', 15.0, 35.0, 10.0, 40.0);

INSERT INTO tipos_planta (nombre, temp_min, temp_max, hum_min, hum_max) 
VALUES ('pensamiento', 5.0, 20.0, 50.0, 80.0);

INSERT INTO plantas (nombre, nombre_duenio, tipo_id) VALUES ('Mi Planta', 'Dueño', 1);
INSERT INTO plantas (nombre, nombre_duenio, tipo_id) VALUES ('Plunto Plonto', 'Diego Salcedo', 2);


SELECT nombre, duenio, tipo_planta, alertas
FROM obtener_estado_planta_por_id(2)
WHERE estado_general = 'Requiere Atención'
ORDER BY tipo_planta ASC;

SELECT t.nombre AS especie, COUNT(p.id_planta) AS total_plantas
FROM tipos_planta t
LEFT JOIN plantas p ON t.id_tipo_planta = p.tipo_id
WHERE p.ultima_temp BETWEEN t.temp_min AND t.temp_max
  AND p.ultima_hum BETWEEN t.hum_min AND t.hum_max
GROUP BY t.nombre;

DROP FUNCTION obtener_estado_plantas()

-- 2. Después, crea la función (esto suele requerir ir en un bloque aparte en la mayoría de gestores)
CREATE OR REPLACE FUNCTION obtener_estado_planta_por_id(p_id_planta INT)
RETURNS TABLE(
    nombre VARCHAR, 
    duenio VARCHAR, 
    tipo_planta VARCHAR, 
    temp_actual NUMERIC, 
    hum_actual NUMERIC, 
    alertas TEXT, 
    estado_general TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.nombre,
        p.nombre_duenio,
        t.nombre,
        p.ultima_temp,
        p.ultima_hum,
        CONCAT_WS(' | ', 
            CASE 
                WHEN p.ultima_hum < t.hum_min THEN 'Necesita Agua' 
                WHEN p.ultima_hum > t.hum_max THEN 'Exceso de Humedad' 
                ELSE NULL 
            END,
            CASE 
                WHEN p.ultima_temp < t.temp_min THEN 'Necesita Calor'
                WHEN p.ultima_temp > t.temp_max THEN 'Temperatura Alta' 
                ELSE NULL 
            END
        ),
        CASE 
            WHEN p.ultima_temp BETWEEN t.temp_min AND t.temp_max 
                 AND p.ultima_hum BETWEEN t.hum_min AND t.hum_max 
            THEN 'Perfectas condiciones'
            ELSE 'Requiere Atención'
        END
    FROM plantas p
    JOIN tipos_planta t ON p.tipo_id = t.id_tipo_planta
    WHERE p.id_planta = p_id_planta; -- AQUÍ ESTÁ EL CAMBIO CLAVE
END;
$$ LANGUAGE plpgsql;