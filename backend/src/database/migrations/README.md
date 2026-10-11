# Migraciones

Aquí van las migraciones generadas por TypeORM (archivos `*.ts`).

- Generar (después de cambiar una entidad): `npm run migration:generate -- src/database/migrations/NombreDelCambio`
- Aplicar: `npm run migration:run` (en producción se aplican solas al arrancar con `DB_MIGRATIONS_RUN=true`)
- Deshacer la última: `npm run migration:revert`

La primera migración (`InitialSchema`) se genera contra una base **vacía**; ver DEPLOY.md.
