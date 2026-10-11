import { Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { mkdirSync } from 'fs';
import { unlink, writeFile } from 'fs/promises';
import { join, normalize, resolve } from 'path';
import { FileStorage, IMAGE_TYPES, StoredFile, UploadInput } from './file-storage';

/**
 * ADAPTADOR local: guarda en disco (UPLOAD_DIR) y sirve en /uploads.
 * Solo para desarrollo: en Render (plan gratis) el disco se borra en cada
 * reinicio o despliegue, por eso en producción se usa Cloudinary.
 */
export class LocalFileStorage implements FileStorage {
  readonly driver = 'local';
  private readonly logger = new Logger(LocalFileStorage.name);
  private readonly root: string;

  constructor(
    uploadDir: string,
    private readonly publicUrl: string,
  ) {
    this.root = resolve(uploadDir);
  }

  async upload(file: UploadInput, folder: string): Promise<StoredFile> {
    const safeFolder = normalize(folder).replace(/^(\.\.(\/|\\|$))+/, '');
    const dir = join(this.root, safeFolder);
    mkdirSync(dir, { recursive: true });
    const name = `${randomUUID()}${IMAGE_TYPES[file.mimetype] ?? ''}`;
    await writeFile(join(dir, name), file.buffer);
    const key = `${safeFolder.replace(/\\/g, '/')}/${name}`;
    return { url: `${this.publicUrl.replace(/\/$/, '')}/uploads/${key}`, key };
  }

  async delete(key: string): Promise<void> {
    try {
      await unlink(join(this.root, normalize(key)));
    } catch (e) {
      this.logger.warn(`No se pudo borrar ${key}: ${(e as Error).message}`);
    }
  }
}
