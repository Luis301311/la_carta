import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import { Public } from '../auth/decorators/public.decorator';
import { CreateOrderDto } from '../orders/dto/order.dto';
import { PublicService } from './public.service';

/** Rutas SIN login que usa la app del cliente final */
@ApiTags('public')
@Public()
@Controller('public/:slug')
export class PublicController {
  constructor(private readonly publicService: PublicService) {}

  /** Menú completo del restaurante: datos, horario, pagos, categorías y productos con extras */
  @Get('menu')
  getMenu(@Param('slug') slug: string) {
    return this.publicService.getMenu(slug);
  }

  @Post('orders')
  createOrder(@Param('slug') slug: string, @Body() dto: CreateOrderDto) {
    return this.publicService.createOrder(slug, dto);
  }

  /**
   * Comprobante de transferencia (multipart): campo `file` (imagen) y
   * campo `token` (el `proofToken` que devolvió POST /orders).
   */
  @Post('orders/:orderId/proof')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
        token: { type: 'string' },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      // En memoria: se escribe a disco solo si la clave es válida
      storage: memoryStorage(),
      limits: { fileSize: 8 * 1024 * 1024 },
    }),
  )
  attachProof(
    @Param('slug') slug: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body('token') token: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.publicService.attachProof(slug, orderId, String(token ?? ''), file);
  }
}
