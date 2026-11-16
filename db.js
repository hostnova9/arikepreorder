const { Pool } = require('pg');
const { AsyncLocalStorage } = require('node:async_hooks');
const scope = new AsyncLocalStorage();
function createPool(env = process.env) {
  const connectionString = env.DATABASE_URL;
  const pool = new Pool(connectionString ? {
    connectionString, ssl: { rejectUnauthorized: true }, max: 1,
    connectionTimeoutMillis: 10000, idleTimeoutMillis: 10000
  } : {
    host: env.DB_HOST, port: env.DB_PORT || 5432,
    database: env.DB_NAME, user: env.DB_USER, password: env.DB_PASSWORD,
    ssl: env.DB_SSL === 'true' ? { rejectUnauthorized: true } : undefined,
    connectionTimeoutMillis: 10000, max: 1
  });
  pool.on('error', err => console.error('PostgreSQL pool error:', err.message));
  return pool;
}
let localPool;
function currentPool() {
  const store = scope.getStore();
  if (store) return store.pool || (store.pool = createPool(store.env));
  return localPool || (localPool = createPool());
}
async function withRequest(env, ctx, handler) {
  const store = { env, pool: null };
  return scope.run(store, async () => {
    try { return await handler(); }
    finally {
      if (store.pool) ctx.waitUntil(store.pool.end().catch(err =>
        console.error('PostgreSQL cleanup:', err.message)));
    }
  });
}
module.exports = new Proxy({ withRequest }, {
  get(target, key) {
    if (key in target) return target[key];
    const pool = currentPool();
    const value = pool[key];
    return typeof value === 'function' ? value.bind(pool) : value;
  }
});
