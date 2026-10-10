import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { DataSource, ILike, Repository } from 'typeorm';
import { AuthUser } from '../auth/auth-user.interface';
import { Role } from '../common/enums';
import { Category } from '../categories/category.entity';
import { Order } from '../orders/order.entity';
import { Product } from '../products/product.entity';
import { UsersService } from '../users/users.service';
import { BusinessHour } from './business-hour.entity';
import { Company } from './company.entity';
import {
  CreateCompanyDto,
  InitialAdminDto,
  SetBusinessHoursDto,
  UpdateCompanyDto,
} from './dto/company.dto';
import { isOpenNow } from './opening-hours';

@Injectable()
export class CompaniesService {
  constructor(
    @InjectRepository(Company) private readonly repo: Repository<Company>,
    @InjectRepository(BusinessHour) private readonly hoursRepo: Repository<BusinessHour>,
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly users: UsersService,
  ) {}

  /** Listado para el panel del super admin, con conteos útiles */
  async findAll(search?: string) {
    const where = search
      ? [{ name: ILike(`%${search}%`) }, { slug: ILike(`%${search}%`) }]
      : undefined;
    const companies = await this.repo.find({ where, order: { createdAt: 'DESC' } });
    if (companies.length === 0) return [];

    const ids = companies.map((c) => c.id);
    const count = async (entity: any, alias: string) => {
      const rows: { companyId: string; count: string }[] = await this.dataSource
        .getRepository(entity)
        .createQueryBuilder(alias)
        .select(`${alias}.company_id`, 'companyId')
        .addSelect('COUNT(*)', 'count')
        .where(`${alias}.company_id IN (:...ids)`, { ids })
        .groupBy(`${alias}.company_id`)
        .getRawMany();
      return new Map(rows.map((r) => [r.companyId, Number(r.count)]));
    };
    const [categories, products, orders] = await Promise.all([
      count(Category, 'c'),
      count(Product, 'p'),
      count(Order, 'o'),
    ]);

    return companies.map((c) => ({
      ...c,
      stats: {
        categories: categories.get(c.id) ?? 0,
        products: products.get(c.id) ?? 0,
        orders: orders.get(c.id) ?? 0,
      },
    }));
  }

  async findOne(id: string) {
    const company = await this.repo.findOne({
      where: { id },
      relations: { businessHours: true },
      order: { businessHours: { dayOfWeek: 'ASC' } },
    });
    if (!company) throw new NotFoundException('Empresa no encontrada');
    return { ...company, isOpenNow: isOpenNow(company.businessHours ?? [], company.timezone) };
  }

  /** Para el menú público: solo empresas activas */
  async findActiveBySlug(slug: string) {
    const company = await this.repo.findOne({
      where: { slug, isActive: true },
      relations: { businessHours: true },
      order: { businessHours: { dayOfWeek: 'ASC' } },
    });
    if (!company) throw new NotFoundException('Restaurante no encontrado');
    return company;
  }

  async create(dto: CreateCompanyDto) {
    const { admin, ...data } = dto;
    await this.assertSlugFree(data.slug);

    return this.dataSource.transaction(async (manager) => {
      const company = await manager.getRepository(Company).save(manager.create(Company, data));
      let createdAdmin: unknown = null;
      if (admin) {
        createdAdmin = await this.users.create(
          { ...admin, role: Role.COMPANY_ADMIN, companyId: company.id },
          manager,
        );
      }
      return { company, admin: createdAdmin };
    });
  }

  async update(id: string, dto: UpdateCompanyDto, user: AuthUser) {
    const company = await this.repo.findOne({ where: { id } });
    if (!company) throw new NotFoundException('Empresa no encontrada');

    if (dto.slug !== undefined && dto.slug !== company.slug) {
      if (user.role !== Role.SUPER_ADMIN) {
        throw new ForbiddenException('Solo el super admin puede cambiar el slug');
      }
      await this.assertSlugFree(dto.slug);
    }
    Object.assign(company, dto);
    await this.repo.save(company);
    return this.findOne(id);
  }

  async setActive(id: string, isActive: boolean) {
    const res = await this.repo.update(id, { isActive });
    if (!res.affected) throw new NotFoundException('Empresa no encontrada');
    return this.findOne(id);
  }

  async remove(id: string) {
    const res = await this.repo.delete(id);
    if (!res.affected) throw new NotFoundException('Empresa no encontrada');
    return { ok: true };
  }

  /** Reemplaza todos los horarios de la empresa */
  async setBusinessHours(companyId: string, dto: SetBusinessHoursDto) {
    const days = dto.hours.map((h) => h.dayOfWeek);
    if (new Set(days).size !== days.length) {
      throw new ConflictException('Hay días repetidos en el horario');
    }
    await this.ensureExists(companyId);
    await this.dataSource.transaction(async (manager) => {
      await manager.delete(BusinessHour, { companyId });
      if (dto.hours.length) {
        await manager.insert(
          BusinessHour,
          dto.hours.map((h) => ({ ...h, companyId })),
        );
      }
    });
    return this.hoursRepo.find({ where: { companyId }, order: { dayOfWeek: 'ASC' } });
  }

  // ---- Admins de la empresa (gestionados por el super admin) ----

  async listAdmins(companyId: string) {
    await this.ensureExists(companyId);
    return this.users.findByCompany(companyId);
  }

  async createAdmin(companyId: string, dto: InitialAdminDto) {
    await this.ensureExists(companyId);
    return this.users.create({ ...dto, role: Role.COMPANY_ADMIN, companyId });
  }

  async setAdminActive(companyId: string, userId: string, isActive: boolean) {
    const user = await this.users.findOne({ id: userId, companyId });
    if (!user) throw new NotFoundException('Usuario no encontrado en esta empresa');
    await this.users.setActive(userId, isActive);
    return { ok: true };
  }

  async resetAdminPassword(companyId: string, userId: string, password: string) {
    const user = await this.users.findOne({ id: userId, companyId });
    if (!user) throw new NotFoundException('Usuario no encontrado en esta empresa');
    await this.users.setPassword(userId, password);
    return { ok: true };
  }

  async ensureExists(id: string) {
    if (!(await this.repo.exists({ where: { id } }))) {
      throw new NotFoundException('Empresa no encontrada');
    }
  }

  private async assertSlugFree(slug: string) {
    if (await this.repo.exists({ where: { slug } })) {
      throw new ConflictException(`El slug "${slug}" ya está en uso`);
    }
  }
}
