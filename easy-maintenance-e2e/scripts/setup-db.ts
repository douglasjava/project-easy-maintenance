import * as mysql from 'mysql2/promise';
import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config({ path: path.resolve(__dirname, '../.env.e2e') });

const DB_HOST = process.env.DB_HOST ?? 'localhost';
const DB_PORT = parseInt(process.env.DB_PORT ?? '3307');
const DB_USER = process.env.DB_USER ?? 'easy_user';
const DB_PASSWORD = process.env.DB_PASSWORD ?? 'easy_pass';
const DB_NAME = process.env.DB_NAME ?? 'easy_maintenance';

async function run(): Promise<void> {
  const conn = await mysql.createConnection({
    host: DB_HOST,
    port: DB_PORT,
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME,
    multipleStatements: true,
  });

  const seedPath = path.resolve(__dirname, '../seed/e2e-seed.sql');
  const sql = fs.readFileSync(seedPath, 'utf-8');

  console.log(`Connecting to ${DB_HOST}:${DB_PORT}/${DB_NAME}...`);

  try {
    await conn.query(sql);
    console.log('E2E seed applied successfully.');
  } finally {
    await conn.end();
  }
}

run().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
