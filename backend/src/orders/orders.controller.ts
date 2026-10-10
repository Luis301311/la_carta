import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CompanyAccessGuard } from '../auth/guards/company-access.guard';
import { ListOrdersQueryDto, UpdateOrderStatusDto } from './dto/order.dto';
import { OrdersService } from './orders.service';

/** Panel de pedidos de cada empresa (los pedidos se crean desde /public) */
@ApiTags('orders')
@ApiBearerAuth()
@UseGuards(CompanyAccessGuard)
@Controller('companies/:companyId/orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Get()
  findAll(@Param('companyId') companyId: string, @Query() query: ListOrdersQueryDto) {
    return this.orders.findAll(companyId, query);
  }

  /** ¿Cambió algo? (va antes de ':id' para que no la tome como un id) */
  @Get('last-change')
  lastChange(@Param('companyId') companyId: string) {
    return this.orders.lastChange(companyId);
  }

  @Get(':id')
  findOne(@Param('companyId') companyId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.orders.findOne(companyId, id);
  }

  @Patch(':id/status')
  updateStatus(
    @Param('companyId') companyId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.orders.updateStatus(companyId, id, dto.status);
  }
}
