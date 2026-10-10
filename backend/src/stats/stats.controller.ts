import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CompanyAccessGuard } from '../auth/guards/company-access.guard';
import { StatsService } from './stats.service';

@ApiTags('stats')
@ApiBearerAuth()
@UseGuards(CompanyAccessGuard)
@Controller('companies/:companyId')
export class StatsController {
  constructor(private readonly stats: StatsService) {}

  /** Resumen para el inicio del panel: hoy, ventas de 7 días, productos y pedidos recientes */
  @Get('dashboard')
  dashboard(@Param('companyId') companyId: string) {
    return this.stats.dashboard(companyId);
  }
}
