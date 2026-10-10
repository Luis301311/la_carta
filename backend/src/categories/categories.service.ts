import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../products/product.entity';
import { Category } from './category.entity';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';

/** Todas las operaciones van filtradas por companyId: nunca se cruza información entre empresas. */
@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category) private readonly repo: Repository<Category>,
    @InjectRepository(Product) private readonly products: Repository<Product>,
  ) {}

  findAll(companyId: string, onlyActive = false) {
    return this.repo.find({
      where: onlyActive ? { companyId, isActive: true } : { companyId },
      order: { sortOrder: 'ASC', name: 'ASC' },
    });
  }

  async findOne(companyId: string, id: string) {
    const category = await this.repo.findOne({ where: { id, companyId } });
    if (!category) throw new NotFoundException('Categoría no encontrada');
    return category;
  }

  create(companyId: string, dto: CreateCategoryDto) {
    return this.repo.save(this.repo.create({ ...dto, companyId }));
  }

  async update(companyId: string, id: string, dto: UpdateCategoryDto) {
    const category = await this.findOne(companyId, id);
    Object.assign(category, dto);
    return this.repo.save(category);
  }

  async remove(companyId: string, id: string) {
    const category = await this.findOne(companyId, id);
    const count = await this.products.count({ where: { companyId, categoryId: id } });
    if (count > 0) {
      throw new ConflictException(
        `La categoría tiene ${count} producto(s). Muévelos o elimínalos primero, o desactívala.`,
      );
    }
    await this.repo.remove(category);
    return { ok: true };
  }
}
