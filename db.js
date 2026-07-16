require('dotenv').config();
const { Pool } = require('pg');
const { MongoClient } = require('mongodb');

// Postgres
const pgPool = new Pool({ connectionString: process.env.DATABASE_URL });

// MongoDB
const mongoClient = new MongoClient(process.env.MONGO_URI);

async function connectDBs() {
    await mongoClient.connect();
    console.log("✅ Conectado a MongoDB");
    // Verificamos conexión a Postgres
    const pgClient = await pgPool.connect();
    pgClient.release();
    console.log("✅ Conectado a PostgreSQL");
    
    return { 
        mongoDb: mongoClient.db(), 
        pgPool 
    };
}

module.exports = { connectDBs };