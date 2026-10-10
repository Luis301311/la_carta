import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';
import { Category } from '../categories/category.entity';
import { CreateProductDto, ExtraGroupDto, UpdateProductDto } from './dto/product.dto';
import { ExtraGroup } from './extra-group.entity';
import { ExtraOption } from './extra-option.entity';
import { Product } from './product.entity';

const WITH_EXTRAS = { extraGroups: { options: true } } as const;
const EXTRAS_ORDER = {
  extraGroups: { sortOrder: 'ASC', options: { sortOrder: 'ASC' } },
} as const;

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Product) private readonly repo: Repository<Product>,
    @InjectRepository(Category) private readonly categories: Repository<Category>,
    @InjectDataSource() private readonly dataSource: DataSource,
  ) {}

  findAll(companyId: string, opts: { categoryId?: string; onlyAvailable?: boolean } = {}) {
    return this.repo.find({
      where: {
        companyId,
        ...(opts.categoryId ? { categoryId: opts.categoryId } : {}),
        ...(opts.onlyAvailable ? { isAvailable: true } : {}),
      },
      relations: WITH_EXTRAS,
      order: { sortOrder: 'ASC', name: 'ASC', ...EXTRAS_ORDER },
    });
  }

  async findOne(companyId: string, id: string) {
    const product = await this.repo.findOne({
      where: { id, companyId },
      relations: WITH_EXTRAS,
      order: EXTRAS_ORDER,
    });
    if (!product) throw new NotFoundException('Producto no encontrado');
    return product;
  }

  async create(companyId: string, dto: CreateProductDto) {
    const { extraGroups, ...data } = dto;
    await this.assertCategory(companyId, data.categoryId);
    this.validateExtras(extraGroups);

    const id = await this.dataSource.transaction(async (manager) => {
      const product = await manager.save(
        manager.create(Product, { ...data, description: data.description ?? '', companyId }),
      );
      await this.replaceExtras(manager, product.id, extraGroups ?? []);
      return product.id;
    });
    return this.findOne(companyId, id);
  }

  async update(companyId: string, id: string, dto: UpdateProductDto) {
    const { extraGroups, ...data } = dto;
    const product = await this.repo.findOne({ where: { id, companyId } });
    if (!product) throw new NotFoundException('Producto no encontrado');
    if (data.categoryId && data.categoryId !== product.categoryId) {
      await this.assertCategory(companyId, data.categoryId);
    }
    this.validateExtras(extraGroups);

    await this.dataSource.transaction(async (manager) => {
      Object.assign(product, data);
      await manager.save(product);
      if (extraGroups !== undefined) {
        await this.replaceExtras(manager, id, extraGroups);
      }
    });
    return this.findOne(companyId, id);
  }

  async setAvailability(companyId: string, id: string, isAvailable: boolean) {
    const res = await this.repo.update({ id, companyId }, { isAvailable });
    if (!res.affected) throw new NotFoundException('Producto no encontrado');
    return this.findOne(companyId, id);
  }

  async remove(companyId: string, id: string) {
    const res = await this.repo.delete({ id, companyId });
    if (!res.affected) throw new NotFoundException('Producto no encontrado');
    return { ok: true };
  }

  // ---------- helpers ----------

  private async assertCategory(companyId: string, categoryId: string) {
    const ok = await this.categories.exists({ where: { id: categoryId, companyId } });
    if (!ok) throw new BadRequestException('La categoría no existe en esta empresa');
  }

  private validateExtras(groups?: ExtraGroupDto[]) {
    for (const g of groups ?? []) {
      if (g.minSelection > g.maxSelection) {
        throw new BadRequestException(`"${g.title}": minSelection no puede ser mayor que maxSelection`);
      }
      if (g.isRequired && g.minSelection < 1) {
        throw new BadRequestException(`"${g.title}": si es obligatorio, minSelection debe ser al menos 1`);
      }
      if (g.options.length < g.minSelection) {
        throw new BadRequestException(`"${g.title}": tiene menos opciones que minSelection`);
      }
    }
  }

  /** Borra los grupos de extras del producto y crea los nuevos (las opciones caen en cascada) */
  private async replaceExtras(manager: EntityManager, productId: string, groups: ExtraGroupDto[]) {
    await manager.delete(ExtraGroup, { productId });
    for (const [gi, g] of groups.entries()) {
      const group = await manager.save(
        manager.create(ExtraGroup, {
          productId,
          title: g.title,
          isRequired: g.isRequired,
          minSelection: g.minSelection,
          maxSelection: g.maxSelection,
          sortOrder: gi,
        }),
      );
      if (g.options.length) {
        await manager.insert(
          ExtraOption,
          g.options.map((o, oi) => ({
            groupId: group.id,
            name: o.name,
            price: o.price,
            isActive: o.isActive ?? true,
            sortOrder: oi,
          })),
        );
      }
    }
  }
}
