import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: 'superadmin@lacarta.app' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'CambiaEsto123' })
  @IsString()
  @MinLength(6)
  password: string;
}
