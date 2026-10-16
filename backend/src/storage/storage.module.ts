import { Global, Logger, Module } from '@nestjs/common';
import { APP_CONFIG, AppConfig } from '../config/app-config';
import { CloudinaryFileStorage } from './cloudinary-file-storage';
import { FILE_STORAGE, FileStorage } from './file-storage';
import { LocalFileStorage } from './local-file-storage';

/**
 * Aquí (y solo aquí) se decide qué adaptador de almacenamiento se usa.
 * Global: cualquier módulo puede inyectar FILE_STORAGE sin importarlo.
 */
@Global()
@Module({
  providers: [
    {
      provide: FILE_STORAGE,
      inject: [APP_CONFIG],
      useFactory: ({ storage: cfg }: AppConfig): FileStorage => {
        let storage: FileStorage;
        switch (cfg.driver) {
          case 'cloudinary':
            storage = new CloudinaryFileStorage(cfg.cloudinary);
            break;
          // case 's3': storage = new S3FileStorage(cfg.s3); break;
          case 'local':
            storage = new LocalFileStorage(cfg.local.uploadDir, cfg.local.publicUrl);
            break;
          default: {
            // Si agregas un driver en env.validation.ts y olvidas este case,
            // TypeScript marca error aquí
            const unknownDriver: never = cfg.driver;
            throw new Error(`STORAGE_DRIVER sin adaptador: ${String(unknownDriver)}`);
          }
        }
        new Logger('StorageModule').log(`Almacenamiento de archivos: ${storage.driver}`);
        return storage;
      },
    },
  ],
  exports: [FILE_STORAGE],
})
export class StorageModule {}
