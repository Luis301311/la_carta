import { Global, Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
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
      inject: [ConfigService],
      useFactory: (config: ConfigService): FileStorage => {
        const driver = (config.get<string>('STORAGE_DRIVER') ?? 'local').toLowerCase();
        let storage: FileStorage;
        switch (driver) {
          case 'cloudinary':
            storage = new CloudinaryFileStorage({
              url: config.get<string>('CLOUDINARY_URL'),
              cloudName: config.get<string>('CLOUDINARY_CLOUD_NAME'),
              apiKey: config.get<string>('CLOUDINARY_API_KEY'),
              apiSecret: config.get<string>('CLOUDINARY_API_SECRET'),
              rootFolder: config.get<string>('CLOUDINARY_FOLDER') ?? 'lacarta',
            });
            break;
          // case 's3': storage = new S3FileStorage({...}); break;
          case 'local':
            storage = new LocalFileStorage(
              config.get<string>('UPLOAD_DIR') ?? 'uploads',
              config.get<string>('PUBLIC_URL') ?? 'http://localhost:3000',
            );
            break;
          default:
            throw new Error(`STORAGE_DRIVER desconocido: "${driver}" (usa local o cloudinary)`);
        }
        new Logger('StorageModule').log(`Almacenamiento de archivos: ${storage.driver}`);
        return storage;
      },
    },
  ],
  exports: [FILE_STORAGE],
})
export class StorageModule {}
