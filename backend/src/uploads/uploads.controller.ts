import {
  BadRequestException,
  Controller,
  Inject,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import { CompanyAccessGuard } from '../auth/guards/company-access.guard';
import { loadConfig } from '../config/app-config';
import { FILE_STORAGE, FileStorage, IMAGE_TYPES } from '../storage/file-storage';


/**
 * Sube imágenes (productos, logo, portada, QR de pago) de una empresa.
 * No sabe DÓNDE se guardan: eso lo decide el adaptador de FILE_STORAGE
 * (disco en desarrollo, Cloudinary en producción).
 */
@ApiTags('uploads')
@ApiBearerAuth()
@UseGuards(CompanyAccessGuard)
@Controller('companies/:companyId/uploads')
export class UploadsController {
  constructor(@Inject(FILE_STORAGE) private readonly storage: FileStorage) {}

  @Post('image')
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } } } })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(), // en memoria; el adaptador decide dónde guardarlo
      // Los decoradores no tienen inyección: se usa el mismo singleton
      limits: { fileSize: loadConfig().storage.maxUploadBytes },
      fileFilter: (_req, file, cb) => {
        if (!IMAGE_TYPES[file.mimetype]) {
          return cb(new BadRequestException('Solo se permiten imágenes JPG, PNG, WEBP o GIF'), false);
        }
        cb(null, true);
      },
    }),
  )
  async upload(@Param('companyId') companyId: string, @UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Envía la imagen en el campo "file"');
    const stored = await this.storage.upload(
      { buffer: file.buffer, mimetype: file.mimetype, originalName: file.originalname },
      `${companyId}/images`,
    );
    return { url: stored.url };
  }
}
