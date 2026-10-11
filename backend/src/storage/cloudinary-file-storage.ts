import { Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { v2 as cloudinary } from 'cloudinary';
import { FileStorage, StoredFile, UploadInput } from './file-storage';

export interface CloudinaryOptions {
  /** CLOUDINARY_URL=cloudinary://API_KEY:API_SECRET@CLOUD_NAME (o los 3 datos por separado) */
  url?: string;
  cloudName?: string;
  apiKey?: string;
  apiSecret?: string;
  /** Carpeta raíz dentro de Cloudinary (p. ej. "lacarta") */
  rootFolder: string;
}

/** ADAPTADOR Cloudinary (producción) */
export class CloudinaryFileStorage implements FileStorage {
  readonly driver = 'cloudinary';
  private readonly logger = new Logger(CloudinaryFileStorage.name);

  constructor(private readonly opts: CloudinaryOptions) {
    if (opts.url) {
      // El SDK lee CLOUDINARY_URL del entorno; se fuerza https
      process.env.CLOUDINARY_URL = opts.url;
      cloudinary.config({ secure: true });
    } else if (opts.cloudName && opts.apiKey && opts.apiSecret) {
      cloudinary.config({
        cloud_name: opts.cloudName,
        api_key: opts.apiKey,
        api_secret: opts.apiSecret,
        secure: true,
      });
    } else {
      throw new Error(
        'STORAGE_DRIVER=cloudinary pero faltan credenciales: define CLOUDINARY_URL ' +
          'o CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY y CLOUDINARY_API_SECRET',
      );
    }
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
