import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class ExtraOptionDto {
  @ApiProperty({ example: 'Tocineta' })
  @IsString() @MinLength(1) @MaxLength(100)
  name: string;

  @ApiProperty({ example: 3000 })
  @IsNumber({ maxDecimalPlaces: 2 }) @Min(0)
  price: number;

  @ApiPropertyOptional({ default: true })
  @IsOptional() @IsBoolean()
  isActive?: boolean;
}

export class ExtraGroupDto {
  @ApiProperty({ example: 'Adiciones' })
  @IsString() @MinLength(1) @MaxLength(100)
  title: string;

  @ApiProperty({ default: false })
  @IsBoolean()
  isRequired: boolean;

  @ApiProperty({ example: 0 })
  @IsInt() @Min(0)
  minSelection: number;

  @ApiProperty({ example: 3 })
  @IsInt() @Min(1)
  maxSelection: number;

  @ApiProperty({ type: [ExtraOptionDto] })
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => ExtraOptionDto)
  options: ExtraOptionDto[];
}

export class CreateProductDto {
  @ApiProperty({ example: 'Hamburguesa clásica' })
  @IsString() @MinLength(1) @MaxLength(150)
  name: string;

  @ApiPropertyOptional({ example: 'Carne 150 g, queso, lechuga y tomate' })
  @IsOptional() @IsString()
  description?: string;

  @ApiProperty({ example: 18000 })
  @IsNumber({ maxDecimalPlaces: 2 }) @Min(0)
  basePrice: number;

  @ApiProperty()
  @IsUUID()
  categoryId: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional() @IsArray() @ArrayMaxSize(10) @IsString({ each: true })
  imageUrls?: string[];

  @ApiPropertyOptional({ default: true })
  @IsOptional() @IsBoolean()
  isAvailable?: boolean;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional() @IsInt() @Min(0)
  sortOrder?: number;

  @ApiPropertyOptional({ type: [ExtraGroupDto], description: 'Al editar, si lo envías reemplaza TODOS los grupos de extras' })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => ExtraGroupDto)
  extraGroups?: ExtraGroupDto[];
}

export class UpdateProductDto extends PartialType(CreateProductDto) {}

export class SetAvailabilityDto {
  @ApiProperty()
  @IsBoolean()
  isAvailable: boolean;
}

export class ListProductsQueryDto {
  @ApiPropertyOptional()
  @IsOptional() @IsUUID()
  categoryId?: string;
}

