import { plainToInstance, Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEmail,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  Matches,
  Max,
  Min,
  MinLength,
  ValidateIf,
  validateSync,
  ValidationError,
} from 'class-validator';

/**
 * REGLAS de cada variable de entorno.
 *
 * Es el único lugar donde se definen nombres, tipos y valores por defecto.
 * Si una variable no cumple, la API (o el seed, o la CLI de migraciones)
 * NO arranca y dice exactamente cuál falta o está mal (fail-fast).
 */

const toBool = ({ value }: { value: unknown }) =>
  value === true || String(value).trim().toLowerCase() === 'true';
const toLower = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().toLowerCase() : value;

export const NODE_ENVS = ['development', 'production', 'test'] as const;
export const STORAGE_DRIVERS = ['local', 'cloudinary'] as const; // agrega 's3' cuando exista

export class EnvironmentVariables {
  // ---------------------------------------------------------------- Servidor
  @IsIn(NODE_ENVS)
  @Transform(toLower)
  NODE_ENV: (typeof NODE_ENVS)[number] = 'development';

  // class-validator revisa los decoradores de abajo hacia arriba
  @Max(65535, { message: 'PORT debe ser como máximo 65535' })
  @Min(1, { message: 'PORT debe ser mayor que 0' })
  @IsInt({ message: 'PORT debe ser un número entero' })
  @Type(() => Number)
  PORT = 3000;

  @IsUrl({ require_tld: false, require_protocol: true }, { message: 'PUBLIC_URL debe ser una URL (https://...)' })
  PUBLIC_URL = 'http://localhost:3000';

  /** Separados por coma. Vacío = cualquiera (solo en desarrollo) */
  @IsString()
  CORS_ORIGINS = '';

  // ------------------------------------------------------------ Base de datos
  /** Si existe, tiene prioridad sobre DB_HOST/DB_PORT/... */
  @IsOptional()
  @Matches(/^postgres(ql)?:\/\/.+/, {
    message: 'DATABASE_URL debe empezar por postgresql:// (o déjala comentada para usar DB_HOST)',
  })
  DATABASE_URL?: string;

  @IsString() DB_HOST = 'localhost';
  @IsInt({ message: 'DB_PORT debe ser un número entero' }) @Type(() => Number) DB_PORT = 5432;
  @IsString() DB_USER = 'lacarta';
  @IsString() DB_PASSWORD = 'lacarta';
  @IsString() DB_NAME = 'lacarta';

  @Transform(toBool) @IsBoolean() DB_SSL = false;
  @Transform(toBool) @IsBoolean() DB_SYNC = false;
  @Transform(toBool) @IsBoolean() DB_MIGRATIONS_RUN = false;
  @Transform(toBool) @IsBoolean() DB_LOGGING = false;

  // ----------------------------------------------------------- Autenticación
  @MinLength(16, { message: 'JWT_SECRET debe tener al menos 16 caracteres' })
  @IsString({ message: 'JWT_SECRET es obligatoria' })
  JWT_SECRET!: string;

  @Min(60, { message: 'JWT_EXPIRES_IN_SECONDS debe ser al menos 60' })
  @IsInt({ message: 'JWT_EXPIRES_IN_SECONDS debe ser un número entero (segundos)' })
  @Type(() => Number)
  JWT_EXPIRES_IN_SECONDS = 86400;

  // ---------------------------------------------------------------- Archivos
  @Transform(toLower)
  @IsIn(STORAGE_DRIVERS, { message: `STORAGE_DRIVER debe ser uno de: ${STORAGE_DRIVERS.join(', ')}` })
  STORAGE_DRIVER: (typeof STORAGE_DRIVERS)[number] = 'local';

  @IsString() UPLOAD_DIR = 'uploads';

  @Max(50, { message: 'MAX_UPLOAD_MB debe ser como máximo 50' })
  @Min(1, { message: 'MAX_UPLOAD_MB debe ser al menos 1' })
  @IsInt({ message: 'MAX_UPLOAD_MB debe ser un número entero' })
  @Type(() => Number)
  MAX_UPLOAD_MB = 5;

  /** cloudinary://API_KEY:API_SECRET@CLOUD_NAME (o los 3 datos por separado) */
  @ValidateIf((e: EnvironmentVariables) => e.STORAGE_DRIVER === 'cloudinary' && !e.CLOUDINARY_CLOUD_NAME)
  @Matches(/^cloudinary:\/\/[^:]+:[^@]+@.+/, {
    message: 'CLOUDINARY_URL debe verse así: cloudinary://API_KEY:API_SECRET@CLOUD_NAME',
  })
  @IsNotEmpty({ message: 'CLOUDINARY_URL es obligatoria con STORAGE_DRIVER=cloudinary' })
  CLOUDINARY_URL?: string;

  @IsOptional() @IsString() CLOUDINARY_CLOUD_NAME?: string;

  @ValidateIf((e: EnvironmentVariables) => !!e.CLOUDINARY_CLOUD_NAME)
  @IsNotEmpty({ message: 'Con CLOUDINARY_CLOUD_NAME también hace falta CLOUDINARY_API_KEY' })
  CLOUDINARY_API_KEY?: string;

  @ValidateIf((e: EnvironmentVariables) => !!e.CLOUDINARY_CLOUD_NAME)
  @IsNotEmpty({ message: 'Con CLOUDINARY_CLOUD_NAME también hace falta CLOUDINARY_API_SECRET' })
  CLOUDINARY_API_SECRET?: string;

  @IsString() CLOUDINARY_FOLDER = 'lacarta';

  // -------------------------------------------------------------------- Seed
  @IsEmail({}, { message: 'SUPERADMIN_EMAIL debe ser un correo válido' })
  SUPERADMIN_EMAIL = 'superadmin@lacarta.app';

  @MinLength(8, { message: 'SUPERADMIN_PASSWORD debe tener al menos 8 caracteres' })
  SUPERADMIN_PASSWORD = 'CambiaEsto123';

  @IsString() SUPERADMIN_NAME = 'Super Admin';

  @Transform(toBool) @IsBoolean() SEED_DEMO = false;
}

/** Valores que vienen en .env.example y nunca deben llegar a producción */
const EXAMPLE_JWT_SECRETS = ['cambia-esto-por-un-secreto-largo'];

/** Reglas extra que solo aplican con NODE_ENV=production */
function productionRules(env: EnvironmentVariables): { errors: string[]; warnings: string[] } {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (env.NODE_ENV !== 'production') return { errors, warnings };

  if (env.JWT_SECRET.length < 32 || EXAMPLE_JWT_SECRETS.includes(env.JWT_SECRET)) {
    errors.push('JWT_SECRET: en producción usa un secreto aleatorio de 32+ caracteres');
  }
  if (env.DB_SYNC) {
    errors.push('DB_SYNC: debe ser false en producción (usa migraciones: DB_MIGRATIONS_RUN=true)');
  }
  if (env.STORAGE_DRIVER === 'local') {
    warnings.push('STORAGE_DRIVER=local: en Render el disco se borra en cada despliegue (usa cloudinary)');
  }
  if (!env.DB_SSL) {
    warnings.push('DB_SSL=false: Neon y casi todas las bases en la nube exigen SSL (DB_SSL=true)');
  }
  if (!env.CORS_ORIGINS.trim()) {
    warnings.push('CORS_ORIGINS vacío: cualquier sitio web puede llamar a la API');
  }
  return { errors, warnings };
}

function flatten(errors: ValidationError[]): string[] {
  return errors.flatMap((e) =>
    e.constraints
      ? Object.values(e.constraints).map((msg) => `${e.property}: ${msg}`)
      : flatten(e.children ?? []),
  );
}

export class InvalidEnvironmentError extends Error {
  constructor(readonly problems: string[]) {
    super(
      `Configuración inválida (.env o variables del servidor):\n` +
        problems.map((p) => `  - ${p}`).join('\n'),
    );
    this.name = 'InvalidEnvironmentError';
  }
}

/**
 * Convierte process.env (todo texto) en un objeto tipado y validado.
 * Las variables vacías (`CORS_ORIGINS=`) se tratan como no definidas,
 * así toman su valor por defecto.
 */
export function validateEnv(raw: NodeJS.ProcessEnv): { env: EnvironmentVariables; warnings: string[] } {
  const cleaned = Object.fromEntries(
    Object.entries(raw).filter(([, v]) => v !== undefined && v.trim() !== ''),
  );
  const env = plainToInstance(EnvironmentVariables, cleaned, { exposeDefaultValues: true });
  const problems = flatten(validateSync(env, { skipMissingProperties: false, stopAtFirstError: true }));

  const extra = problems.length ? { errors: [], warnings: [] } : productionRules(env);
  problems.push(...extra.errors);

  if (problems.length) throw new InvalidEnvironmentError(problems);
  return { env, warnings: extra.warnings };
}
