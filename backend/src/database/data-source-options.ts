import { join } from 'path';
import { DataSourceOptions } from 'typeorm';
import { AppConfig, loadConfig } from '../config/app-config';
import { SnakeNamingStrategy } from './snake-naming.strategy';

/**
 * Configuración de TypeORM compartida por la API, el seed y la CLI de
 * migraciones. Recibe la sección `database` de AppConfig (por defecto, la
 * configuración global ya validada).
 */
export function buildDataSourceOptions(
  db: AppConfig['database'] = loadConfig().database,
): DataSourceOptions {
  return {
    type: 'postgres',
    ...(db.url
      ? { url: db.url }
      : {
          host: db.host,
          port: db.port,
          username: db.username,
          password: db.password,
          database: db.name,
        }),
    ssl: db.ssl ? { rejectUnauthorized: false } : false,
    entities: [join(__dirname, '..', '**', '*.entity.{ts,js}')],
    migrations: [join(__dirname, 'migrations', '*.{ts,js}')],
    // Desarrollo: DB_SYNC=true (TypeORM ajusta las tablas solo).
    // Producción: DB_SYNC=false y DB_MIGRATIONS_RUN=true (aplica las migraciones al arrancar).
    synchronize: db.synchronize,
    migrationsRun: db.migrationsRun,
    logging: db.logging,
    namingStrategy: new SnakeNamingStrategy(),
  };
}
