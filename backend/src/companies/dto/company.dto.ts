import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsBoolean,
  IsEmail,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export const SLUG_REGEX = /^[a-z0-9]+(?:[-_][a-z0-9]+)*$/;
const TIME_REGEX = /^([01]\d|2[0-3]):[0-5]\d$/;
const HEX_COLOR_REGEX = /^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;

/** Datos del perfil que puede editar el propio admin de la empresa */
export class CompanyProfileDto {
  @ApiProperty({ example: 'Burger House' })
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  name: string;

  @ApiPropertyOptional({ example: '900123456-7' })
  @IsOptional() @IsString() @MaxLength(40)
  taxId?: string;

  @ApiPropertyOptional({ example: '6055555555' })
  @IsOptional() @IsString() @MaxLength(30)
  phone?: string;

  @ApiPropertyOptional({ example: '573001234567', description: 'Con indicativo, sin +' })
  @IsOptional() @Matches(/^\d{8,15}$/, { message: 'whatsappPhone debe tener solo dígitos (con indicativo)' })
  whatsappPhone?: string;

  @ApiPropertyOptional()
  @IsOptional() @IsEmail()
  email?: string;

  @ApiPropertyOptional()
  @IsOptional() @IsString() @MaxLength(255)
  address?: string;

  @ApiPropertyOptional()
  @IsOptional() @IsLatitude()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional() @IsLongitude()
  longitude?: number;

  @ApiPropertyOptional()
  @IsOptional() @IsString() @MaxLength(500)
  logoUrl?: string;

  @ApiPropertyOptional()
  @IsOptional() @IsString() @MaxLength(500)
  coverUrl?: string;

  @ApiPropertyOptional({ example: '#E53935' })
  @IsOptional() @Matches(HEX_COLOR_REGEX, { message: 'primaryColor debe ser hex, p. ej. #E53935' })
  primaryColor?: string;

  @ApiPropertyOptional({ example: 'America/Bogota' })
  @IsOptional() @IsString() @MaxLength(60)
  timezone?: string;

  // ---------- Pagos ----------

  @ApiPropertyOptional({ default: true })
  @IsOptional() @IsBoolean()
  acceptsCash?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional() @IsBoolean()
  acceptsTransfer?: boolean;

  @ApiPropertyOptional({ example: '@burgerhouse', description: 'Llave Bre-B' })
  @IsOptional() @IsString() @MaxLength(80)
  breBKey?: string;

  @ApiPropertyOptional({ example: 'Burger House SAS' })
  @IsOptional() @IsString() @MaxLength(120)
  paymentHolder?: string;

  @ApiPropertyOptional({ description: 'URL de la imagen del QR de cobro' })
  @IsOptional() @IsString() @MaxLength(500)
  paymentQrUrl?: string;

  @ApiPropertyOptional()
  @IsOptional() @IsString() @MaxLength(500)
  paymentNotes?: string;
}

export class InitialAdminDto {
  @ApiProperty({ example: 'admin@burgerhouse.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Clave12345' })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiProperty({ example: 'Dueño Burger House' })
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  fullName: string;
}

/** Solo SUPER_ADMIN: crea la empresa y, opcionalmente, su primer admin */
export class CreateCompanyDto extends CompanyProfileDto {
  @ApiProperty({ example: 'burger_house', description: 'minúsculas, números, - o _' })
  @Matches(SLUG_REGEX, { message: 'slug: solo minúsculas, números, - o _' })
  @MaxLength(80)
  slug: string;

  @ApiPropertyOptional({ type: InitialAdminDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => InitialAdminDto)
  admin?: InitialAdminDto;
}

export class UpdateCompanyDto extends PartialType(CompanyProfileDto) {
  @ApiPropertyOptional({ description: 'Solo SUPER_ADMIN puede cambiarlo' })
  @IsOptional()
  @Matches(SLUG_REGEX, { message: 'slug: solo minúsculas, números, - o _' })
  @MaxLength(80)
  slug?: string;
}

export class SetActiveDto {
  @ApiProperty()
  @IsBoolean()
  isActive: boolean;
}

export class BusinessHourDto {
  @ApiProperty({ minimum: 1, maximum: 7, description: '1 = lunes ... 7 = domingo' })
  @IsInt() @Min(1) @Max(7)
  dayOfWeek: number;

  @ApiProperty({ example: '08:00' })
  @Matches(TIME_REGEX, { message: 'openTime debe ser HH:mm' })
  openTime: string;

  @ApiProperty({ example: '22:00' })
  @Matches(TIME_REGEX, { message: 'closeTime debe ser HH:mm' })
  closeTime: string;

  @ApiProperty()
  @IsBoolean()
  closed: boolean;
}

export class SetBusinessHoursDto {
  @ApiProperty({ type: [BusinessHourDto] })
  @ValidateNested({ each: true })
  @Type(() => BusinessHourDto)
  @ArrayMaxSize(7)
  hours: BusinessHourDto[];
}

export class ListCompaniesQueryDto {
  @ApiPropertyOptional({ description: 'Busca por nombre o slug' })
  @IsOptional() @IsString()
  search?: string;
}
