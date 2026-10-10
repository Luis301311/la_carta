import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';
import { RolesGuard } from './auth/guards/roles.guard';
import { CategoriesModule } from './categories/categories.module';
import { CompaniesModule } from './companies/companies.module';
import { buildDataSourceOptions } from './database/data-source-options';
import { OrdersModule } from './orders/orders.module';
import { ProductsModule } from './products/products.module';
import { PublicModule } from './public/public.module';
import { StatsModule } from './stats/stats.module';
import { UploadsModule } from './uploads/uploads.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({ useFactory: () => buildDataSourceOptions() }),
    UsersModule,
    AuthModule,
    CompaniesModule,
    CategoriesModule,
    ProductsModule,
    OrdersModule,
    PublicModule,
    UploadsModule,
    StatsModule,
  ],
  providers: [
    // Orden: primero valida el token, luego el rol
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule {}
