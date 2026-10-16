// Carga .env para cualquier punto de entrada (API, seed, CLI de migraciones).
// No pisa variables que ya existan en el sistema (Render, PowerShell $env:...).
import 'dotenv/config';
import { Logger } from '@nestjs/common';
import { EnvironmentVariables, validateEnv } from './env.validation';

/**
 * CONFIGURACIÓN de la aplicación, ya validada, tipada y agrupada por tema.
 *
 * Nadie más lee process.env: los módulos de Nest inyectan APP_CONFIG y los
 * scripts (seed, migraciones) llaman a loadConfig(). Así cada valor por
 * defecto vive en un solo lugar (env.validation.ts).
 */
export interface AppConfig {
  readonly env: 'development' | 'production' | 'test';
  readonly isProduction: boolean;
  readonly server: {
    readonly port: number;
    readonly publicUrl: string;
    /** Vacío = permite cualquier origen */
    readonly corsOrigins: readonly string[];
  };
  readonly database: {
    readonly url?: string;
    readonly host: string;
    readonly port: number;
    readonly username: string;
    readonly password: string;
    readonly name: string;
    readonly ssl: boolean;
    readonly synchronize: boolean;
    readonly migrationsRun: boolean;
    readonly logging: boolean;
  };
  readonly jwt: {
    readonly secret: string;
    readonly expiresInSeconds: number;
  };
  readonly storage: {
    readonly driver: 'local' | 'cloudinary';
    readonly maxUploadBytes: number;
    readonly local: { readonly uploadDir: string; readonly publicUrl: string };
    readonly cloudinary: {
      readonly cloudName?: string;
      readonly apiKey?: string;
      readonly apiSecret?: string;
      readonly rootFolder: string;
    };
  };
  readonly seed: {
    readonly superAdminEmail: string;
    readonly superAdminPassword: string;
    readonly superAdminName: string;
    readonly demo: boolean;
  };
}

/** Token de inyección: `constructor(@Inject(APP_CONFIG) config: AppConfig)` */
export const APP_CONFIG = Symbol('APP_CONFIG');

/** cloudinary://API_KEY:API_SECRET@CLOUD_NAME → sus 3 partes */
function parseCloudinaryUrl(url: string) {
  const u = new URL(url);
  return {
    apiKey: decodeURIComponent(u.username),
    apiSecret: decodeURIComponent(u.password),
    cloudName: u.hostname,
  };
}

function build(e: EnvironmentVariables): AppConfig {
  const cloudinary = e.CLOUDINARY_URL
    ? parseCloudinaryUrl(e.CLOUDINARY_URL)
    : { cloudName: e.CLOUDINARY_CLOUD_NAME, apiKey: e.CLOUDINARY_API_KEY, apiSecret: e.CLOUDINARY_API_SECRET };

  return {
    env: e.NODE_ENV,
    isProduction: e.NODE_ENV === 'production',
    server: {
      port: e.PORT,
      publicUrl: e.PUBLIC_URL.replace(/\/+$/, ''),
      corsOrigins: e.CORS_ORIGINS.split(',')
        .map((o) => o.trim().replace(/\/+$/, ''))
        .filter(Boolean),
    },
    database: {
      url: e.DATABASE_URL,
      host: e.DB_HOST,
      port: e.DB_PORT,
      username: e.DB_USER,
      password: e.DB_PASSWORD,
      name: e.DB_NAME,
      ssl: e.DB_SSL,
      synchronize: e.DB_SYNC,
      migrationsRun: e.DB_MIGRATIONS_RUN,
      logging: e.DB_LOGGING,
    },
    jwt: { secret: e.JWT_SECRET, expiresInSeconds: e.JWT_EXPIRES_IN_SECONDS },
    storage: {
      driver: e.STORAGE_DRIVER,
      maxUploadBytes: e.MAX_UPLOAD_MB * 1024 * 1024,
      local: { uploadDir: e.UPLOAD_DIR, publicUrl: e.PUBLIC_URL.replace(/\/+$/, '') },
      cloudinary: { ...cloudinary, rootFolder: e.CLOUDINARY_FOLDER },
    },
    seed: {
      superAdminEmail: e.SUPERADMIN_EMAIL,
      superAdminPassword: e.SUPERADMIN_PASSWORD,
      superAdminName: e.SUPERADMIN_NAME,
      demo: e.SEED_DEMO,
    },
  };
}

function deepFreeze<T>(obj: T): T {
  if (obj && typeof obj === 'object') {
    Object.values(obj).forEach(deepFreeze);
    Object.freeze(obj);
  }
  return obj;
}

// ------------------------------------------------------------------ Singleton
let instance: AppConfig | undefined;

/**
 * Devuelve LA configuración (se valida una sola vez y queda congelada:
 * nadie puede modificarla en tiempo de ejecución).
 * Lanza InvalidEnvironmentError si falta algo o está mal.
 */
export function loadConfig(): AppConfig {
  if (!instance) {
    const { env, warnings } = validateEnv(process.env);
    warnings.forEach((w) => new Logger('Config').warn(w));
    instance = deepFreeze(build(env));
  }
  return instance;
}

/** Solo para pruebas: obliga a volver a leer process.env */
export function resetConfigForTesting(): void {
  instance = undefined;
}
