import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { OrderStatus, OrderType, PaymentMethod } from '../../common/enums';

export class OrderItemExtraInputDto {
  @ApiProperty()
  @IsUUID()
  optionId: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional() @IsInt() @Min(1) @Max(20)
  quantity?: number;
}

export class OrderItemInputDto {
  @ApiProperty()
  @IsUUID()
  productId: string;

  @ApiProperty({ example: 2 })
  @IsInt() @Min(1) @Max(100)
  quantity: number;

  @ApiPropertyOptional({ example: 'Sin cebolla' })
  @IsOptional() @IsString() @MaxLength(300)
  comment?: string;

  @ApiPropertyOptional({ type: [OrderItemExtraInputDto] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => OrderItemExtraInputDto)
  extras?: OrderItemExtraInputDto[];
}

/**
 * Lo que envía el menú público. OJO: no lleva precios; el servidor los
 * calcula desde la base de datos para que nadie pueda manipularlos.
 */
export class CreateOrderDto {
  @ApiProperty({ enum: OrderType })
  @IsEnum(OrderType)
  type: OrderType;

  @ApiProperty({ example: 'Luis' })
  @IsString() @MinLength(2) @MaxLength(120)
  customerName: string;

  @ApiPropertyOptional({ example: '3001234567', description: 'Obligatorio: el restaurante avisa por WhatsApp' })
  @IsOptional() @IsString() @MaxLength(30)
  phone?: string;

  @ApiPropertyOptional({ description: 'Obligatorio para domicilio' })
  @IsOptional() @IsString() @MaxLength(255)
  address?: string;

  @ApiPropertyOptional({ description: 'Obligatorio para comer en el sitio' })
  @IsOptional() @IsString() @MaxLength(20)
  tableNumber?: string;

  @ApiPropertyOptional()
  @IsOptional() @IsString() @MaxLength(500)
  notes?: string;

  @ApiPropertyOptional({ enum: PaymentMethod, default: PaymentMethod.CASH })
  @IsOptional() @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;

  @ApiProperty({ type: [OrderItemInputDto] })
  @IsArray()
  @ArrayMinSize(1, { message: 'El pedido debe tener al menos un producto' })
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => OrderItemInputDto)
  items: OrderItemInputDto[];
}

export class UpdateOrderStatusDto {
  @ApiProperty({ enum: OrderStatus })
  @IsEnum(OrderStatus)
  status: OrderStatus;
}

export class ListOrdersQueryDto {
  @ApiPropertyOptional({ enum: OrderStatus })
  @IsOptional() @IsEnum(OrderStatus)
  status?: OrderStatus;

  @ApiPropertyOptional({ example: '2026-10-01' })
  @IsOptional() @IsDateString()
  from?: string;

  @ApiPropertyOptional({ example: '2026-10-31' })
  @IsOptional() @IsDateString()
  to?: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1)
  page?: number;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100)
  limit?: number;
}
