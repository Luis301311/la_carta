/**
 * PUERTO de almacenamiento de archivos (arquitectura hexagonal / puertos y adaptadores).
 *
 * El resto de la API (subida de imágenes, comprobantes de pago…) SOLO conoce
 * esta interfaz. Dónde se guardan los archivos lo decide el ADAPTADOR que se
 * registre en StorageModule según la variable STORAGE_DRIVER:
 *
 *   - local      -> LocalFileStorage      (disco del servidor; para desarrollo)
 *   - cloudinary -> CloudinaryFileStorage (producción)
 *
 * Para usar S3, Google Cloud Storage, Supabase Storage, etc.:
 *   1. Crea `s3-file-storage.ts` con una clase que implemente `FileStorage`.
 *   2. Agrega `case 's3'` en storage.module.ts.
 *   3. Cambia STORAGE_DRIVER=s3 en el .env.
 * No hay que tocar controladores ni servicios.
 */
export interface UploadInput {
  buffer: Buffer;
  mimetype: string;
  originalName?: string;
}

export interface StoredFile {
  /** URL pública para mostrar la imagen */
  url: string;
  /** Identificador interno del proveedor (para poder borrarla después) */
  key: string;
}

export interface FileStorage {
  /** Nombre del proveedor (para logs) */
  readonly driver: string;

  /**
   * Guarda el archivo dentro de `folder` (p. ej. "<companyId>/images").
   * El nombre final lo genera el proveedor (aleatorio, no adivinable).
   */
  upload(file: UploadInput, folder: string): Promise<StoredFile>;

  delete(key: string): Promise<void>;
}

/** Token de inyección: @Inject(FILE_STORAGE) private readonly storage: FileStorage */
export const FILE_STORAGE = Symbol('FILE_STORAGE');

/** Imágenes aceptadas y su extensión */
export const IMAGE_TYPES: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
};
