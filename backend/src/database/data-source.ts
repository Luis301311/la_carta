/**
 * DataSource para la CLI de TypeORM (migraciones). La API usa la misma
 * configuración desde app.module.ts.
 *
 *   npm run migration:generate -- src/database/migrations/NombreDelCambio
 *   npm run migration:run
 *   npm run migration:revert
 */
import 'dotenv/config';
import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { buildDataSourceOptions } from './data-source-options';

export default new DataSource({
  ...buildDataSourceOptions(),
  // La CLI nunca sincroniza: compara entidades vs. base y escribe la migración
  synchronize: false,
  migrationsRun: false,
});
