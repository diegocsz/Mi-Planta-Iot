require('dotenv').config();
const express = require('express');
const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');
const { connectDBs } = require('./db');

const app = express();
const PORT = 3000;

// Servir archivos estáticos (tu index.html debe estar en la carpeta 'public')
app.use(express.static('public'));

async function start() {
    const { mongoDb, pgPool } = await connectDBs();
    const coleccion = mongoDb.collection('registros');

    // Endpoint API para que el frontend consulte el estado
    app.get('/api/estado', async (req, res) => {
        try {
            const result = await pgPool.query('SELECT * FROM obtener_estado_plantas()');
            // Retorna el primer registro (o ajusta según tu lógica)
            res.json(result.rows[0] || {});
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.get('/api/registros', async (req, res) => {
        try {
            const registros = await coleccion.aggregate([
                { $sort: { fecha: -1 } }, // 1. Ordenar por fecha reciente
                { $limit: 20 },           // 2. Tomar solo los últimos 20
                { $project: {             // 3. Limpiar datos (solo temp y hum)
                    _id: 0, 
                    temp: 1, 
                    hum: 1 
                }}
            ]).toArray();
            
            res.json(registros.reverse()); // Invertir para que D3.js los pinte de izquierda a derecha
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    // Iniciar servidor web
    app.listen(PORT, () => console.log(`🌐 Servidor web corriendo en http://localhost:${PORT}`));

    // Configuración Serial Arduino
    const port = new SerialPort({ path: 'COM5', baudRate: 9600 });
    const parser = port.pipe(new ReadlineParser({ delimiter: '\r\n' }));

    console.log("Esperando datos del Arduino...");

    parser.on('data', async (data) => {
        const partes = data.split(',');
        
        if (partes.length === 2) {
            const temp = parseFloat(partes[0].trim());
            const hum = parseFloat(partes[1].trim());
            const planta_id = 1;

            console.log(`Guardando -> Temp: ${temp.toFixed(1)}, Hum: ${hum.toFixed(1)}`);

            try {
                // 1. Guardar Historial en MongoDB
                await coleccion.insertOne({ temp, hum, fecha: new Date() });

                // 2. Actualizar Estado en PostgreSQL
                await pgPool.query(
                    'UPDATE plantas SET ultima_temp = $1, ultima_hum = $2 WHERE id_planta = $3', 
                    [temp, hum, planta_id]
                );

                // 3. Diagnóstico en consola
                const resConsulta = await pgPool.query('SELECT * FROM obtener_estado_plantas() WHERE nombre = $1', ['Mi Planta']);
                
                if (resConsulta.rows.length > 0) {
                    const estado = resConsulta.rows[0];
                    console.log("--- Diagnóstico de la Planta ---");
                    console.log(`Estado: ${estado.estado_general}`);
                    if (estado.alertas) {
                        console.log(`⚠️ Alerta: ${estado.alertas}`);
                    } else {
                        console.log("✅ Todo en orden.");
                    }
                    console.log("--------------------------------");
                }
            } catch (err) {
                console.error("❌ Error en DB:", err.message);
            }
        }
    });
}

start();