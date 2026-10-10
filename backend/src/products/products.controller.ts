import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CompanyAccessGuard } from '../auth/guards/company-access.guard';
import {
  CreateProductDto,
  ListProductsQueryDto,
  SetAvailabilityDto,
  UpdateProductDto,
} from './dto/product.dto';
import { ProductsService } from './products.service';

@ApiTags('products')
@ApiBearerAuth()
@UseGuards(CompanyAccessGuard)
@Controller('companies/:companyId/products')
export class ProductsController {
  constructor(private readonly products: ProductsService) {}

  @Get()
  findAll(@Param('companyId') companyId: string, @Query() query: ListProductsQueryDto) {
    return this.products.findAll(companyId, { categoryId: query.categoryId });
  }

  @Get(':id')
  findOne(@Param('companyId') companyId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.products.findOne(companyId, id);
  }

  @Post()
  create(@Param('companyId') companyId: string, @Body() dto: CreateProductDto) {
    return this.products.create(companyId, dto);
  }

  @Patch(':id')
  update(
    @Param('companyId') companyId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateProductDto,
  ) {
    return this.products.update(companyId, id, dto);
  }

  /** Atajo para marcar "agotado" desde el panel sin mandar todo el producto */
  @Patch(':id/availability')
  setAvailability(
    @Param('companyId') companyId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SetAvailabilityDto,
  ) {
    return this.products.setAvailability(companyId, id, dto.isAvailable);
  }

  @Delete(':id')
  remove(@Param('companyId') companyId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.products.remove(companyId, id);
  }
}
