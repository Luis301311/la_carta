import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';
import { AuthUser } from '../auth/auth-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { CompanyAccessGuard } from '../auth/guards/company-access.guard';
import { Role } from '../common/enums';
import { CompaniesService } from './companies.service';
import {
  CreateCompanyDto,
  InitialAdminDto,
  ListCompaniesQueryDto,
  SetActiveDto,
  SetBusinessHoursDto,
  UpdateCompanyDto,
} from './dto/company.dto';

class ResetPasswordDto {
  @ApiProperty()
  @IsString()
  @MinLength(8)
  password: string;
}

@ApiTags('companies')
@ApiBearerAuth()
@Controller('companies')
export class CompaniesController {
  constructor(private readonly companies: CompaniesService) {}

  // ---------- Solo SUPER_ADMIN ----------

  @Get()
  @Roles(Role.SUPER_ADMIN)
  findAll(@Query() query: ListCompaniesQueryDto) {
    return this.companies.findAll(query.search);
  }

  @Post()
  @Roles(Role.SUPER_ADMIN)
  create(@Body() dto: CreateCompanyDto) {
    return this.companies.create(dto);
  }

  @Patch(':companyId/status')
  @Roles(Role.SUPER_ADMIN)
  @UseGuards(CompanyAccessGuard)
  setActive(@Param('companyId') companyId: string, @Body() dto: SetActiveDto) {
    return this.companies.setActive(companyId, dto.isActive);
  }

  @Delete(':companyId')
  @Roles(Role.SUPER_ADMIN)
  @UseGuards(CompanyAccessGuard)
  remove(@Param('companyId') companyId: string) {
    return this.companies.remove(companyId);
  }

  @Get(':companyId/admins')
  @Roles(Role.SUPER_ADMIN)
  @UseGuards(CompanyAccessGuard)
  listAdmins(@Param('companyId') companyId: string) {
    return this.companies.listAdmins(companyId);
  }

  @Post(':companyId/admins')
  @Roles(Role.SUPER_ADMIN)
  @UseGuards(CompanyAccessGuard)
  createAdmin(@Param('companyId') companyId: string, @Body() dto: InitialAdminDto) {
    return this.companies.createAdmin(companyId, dto);
  }

  @Patch(':companyId/admins/:userId/status')
  @Roles(Role.SUPER_ADMIN)
  @UseGuards(CompanyAccessGuard)
  setAdminActive(
    @Param('companyId') companyId: string,
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() dto: SetActiveDto,
  ) {
    return this.companies.setAdminActive(companyId, userId, dto.isActive);
  }

  @Patch(':companyId/admins/:userId/password')
  @Roles(Role.SUPER_ADMIN)
  @UseGuards(CompanyAccessGuard)
  resetAdminPassword(
    @Param('companyId') companyId: string,
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() dto: ResetPasswordDto,
  ) {
    return this.companies.resetAdminPassword(companyId, userId, dto.password);
  }

  // ---------- SUPER_ADMIN o el admin de ESA empresa ----------

  @Get(':companyId')
  @UseGuards(CompanyAccessGuard)
  findOne(@Param('companyId') companyId: string) {
    return this.companies.findOne(companyId);
  }

  @Patch(':companyId')
  @UseGuards(CompanyAccessGuard)
  update(
    @Param('companyId') companyId: string,
    @Body() dto: UpdateCompanyDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.companies.update(companyId, dto, user);
  }

  @Put(':companyId/hours')
  @UseGuards(CompanyAccessGuard)
  setHours(@Param('companyId') companyId: string, @Body() dto: SetBusinessHoursDto) {
    return this.companies.setBusinessHours(companyId, dto);
  }
}
