const { Pool } = require('pg');
// Cloudflare Workers: nodejs_compat_populate_process_env must be enabled.
const connectionString = process.env.DATABASE_URL;
const pool = connectionString
  ? new Pool({ connectionString, ssl: { rejectUnauthorized: true }, max: 3,
      connectionTimeoutMillis: 10000, idleTimeoutMillis: 10000 })
  : new Pool({host:process.env.DB_HOST,port:process.env.DB_PORT || 5432,
      database:process.env.DB_NAME,user:process.env.DB_USER,password:process.env.DB_PASSWORD,
      ssl:process.env.DB_SSL === 'true' ? {rejectUnauthorized:true} : undefined});
pool.on('error', err => console.error('PostgreSQL pool error:', err.message));
module.exports = pool;
