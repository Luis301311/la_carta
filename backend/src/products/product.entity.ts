import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { decimalTransformer } from '../common/decimal.transformer';
import { Category } from '../categories/category.entity';
import { Company } from '../companies/company.entity';
import { ExtraGroup } from './extra-group.entity';

@Entity('products')
@Index(['companyId', 'categoryId'])
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  companyId: string;

  @ManyToOne(() => Company, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'company_id' })
  company?: Company;

  @Column('uuid')
  categoryId: string;

  /** RESTRICT: no se puede borrar una categoría que todavía tiene productos */
  @ManyToOne(() => Category, (c) => c.products, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'category_id' })
  category?: Category;

  @Column({ length: 150 })
  name: string;

  @Column({ type: 'text', default: '' })
  description: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, transformer: decimalTransformer })
  basePrice: number;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  imageUrls: string[];

  @Column({ default: true })
  isAvailable: boolean;

  @Column({ type: 'int', default: 0 })
  sortOrder: number;

  @OneToMany(() => ExtraGroup, (g) => g.product)
  extraGroups?: ExtraGroup[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
