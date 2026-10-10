import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../auth/decorators/public.decorator';
import { CreateOrderDto } from '../orders/dto/order.dto';
import { PublicService } from './public.service';

/** Rutas SIN login que usa la app del cliente final */
@ApiTags('public')
@Public()
@Controller('public/:slug')
export class PublicController {
  constructor(private readonly publicService: PublicService) {}

  /** Menú completo del restaurante: datos, horario, categorías y productos con extras */
  @Get('menu')
  getMenu(@Param('slug') slug: string) {
    return this.publicService.getMenu(slug);
  }

  @Post('orders')
  createOrder(@Param('slug') slug: string, @Body() dto: CreateOrderDto) {
    return this.publicService.createOrder(slug, dto);
  }
}
