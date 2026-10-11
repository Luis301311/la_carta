import { join } from 'path';
import { DataSourceOptions } from 'typeorm';
import { SnakeNamingStrategy } from './snake-naming.strategy';

/**
 * Configuración de TypeORM compartida por la API y por el seed.
 * Lee directamente de process.env (el .env ya está cargado).
 */
export function buildDataSourceOptions(): DataSourceOptions {
  const env = process.env;
  const ssl = env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false;

  return {
    type: 'postgres',
    ...(env.DATABASE_URL
      ? { url: env.DATABASE_URL }
      : {
          host: env.DB_HOST ?? 'localhost',
          port: parseInt(env.DB_PORT ?? '5432', 10),
          username: env.DB_USER ?? 'lacarta',
          password: env.DB_PASSWORD ?? 'lacarta',
          database: env.DB_NAME ?? 'lacarta',
        }),
    ssl,
    entities: [join(__dirname, '..', '**', '*.entity.{ts,js}')],
    migrations: [join(__dirname, 'migrations', '*.{ts,js}')],
    // Desarrollo: DB_SYNC=true (TypeORM ajusta las tablas solo).
    // Producción: DB_SYNC=false y DB_MIGRATIONS_RUN=true (aplica las migraciones al arrancar).
    synchronize: env.DB_SYNC === 'true',
    migrationsRun: env.DB_MIGRATIONS_RUN === 'true',
    logging: env.DB_LOGGING === 'true',
    namingStrategy: new SnakeNamingStrategy(),
  };
}
