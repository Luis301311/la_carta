import { Module } from '@nestjs/common';
import { CategoriesModule } from '../categories/categories.module';
import { CompaniesModule } from '../companies/companies.module';
import { OrdersModule } from '../orders/orders.module';
import { ProductsModule } from '../products/products.module';
import { PublicController } from './public.controller';
import { PublicService } from './public.service';

@Module({
  imports: [CompaniesModule, CategoriesModule, ProductsModule, OrdersModule],
  controllers: [PublicController],
  providers: [PublicService],
})
export class PublicModule {}
