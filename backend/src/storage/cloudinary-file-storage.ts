import { Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { v2 as cloudinary } from 'cloudinary';
import { FileStorage, StoredFile, UploadInput } from './file-storage';

export interface CloudinaryOptions {
  cloudName?: string;
  apiKey?: string;
  apiSecret?: string;
  /** Carpeta raíz dentro de Cloudinary (p. ej. "lacarta") */
  rootFolder: string;
}

/**
 * ADAPTADOR Cloudinary (producción). Recibe las credenciales ya resueltas
 * por AppConfig (que entiende tanto CLOUDINARY_URL como los 3 datos sueltos).
 */
export class CloudinaryFileStorage implements FileStorage {
  readonly driver = 'cloudinary';
  private readonly logger = new Logger(CloudinaryFileStorage.name);

  constructor(private readonly opts: CloudinaryOptions) {
    if (!opts.cloudName || !opts.apiKey || !opts.apiSecret) {
      throw new Error(
        'STORAGE_DRIVER=cloudinary pero faltan credenciales: define CLOUDINARY_URL ' +
          'o CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY y CLOUDINARY_API_SECRET',
      );
    }
    cloudinary.config({
      cloud_name: opts.cloudName,
      api_key: opts.apiKey,
      api_secret: opts.apiSecret,
      secure: true,
    });
  }

  upload(file: UploadInput, folder: string): Promise<StoredFile> {
    return new Promise((resolvePromise, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: `${this.opts.rootFolder}/${folder}`,
          public_id: randomUUID(),
          resource_type: 'image',
          overwrite: false,
        },
        (error, result) => {
          if (error || !result) {
            this.logger.error(`Error subiendo a Cloudinary: ${error?.message}`);
            return reject(error ?? new Error('Cloudinary no respondió'));
          }
          resolvePromise({ url: result.secure_url, key: result.public_id });
        },
      );
      stream.end(file.buffer);
    });
  }

  async delete(key: string): Promise<void> {
    try {
      await cloudinary.uploader.destroy(key, { resource_type: 'image' });
    } catch (e) {
      this.logger.warn(`No se pudo borrar ${key}: ${(e as Error).message}`);
    }
  }
}
