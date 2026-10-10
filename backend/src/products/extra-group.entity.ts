import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { ExtraOption } from './extra-option.entity';
import { Product } from './product.entity';

/** Ej.: "Elige tu salsa" (mín 1, máx 2) */
@Entity('extra_groups')
export class ExtraGroup {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  productId: string;

  @ManyToOne(() => Product, (p) => p.extraGroups, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'product_id' })
  product?: Product;

  @Column({ length: 100 })
  title: string;

  @Column({ default: false })
  isRequired: boolean;

  @Column({ type: 'int', default: 0 })
  minSelection: number;

  @Column({ type: 'int', default: 1 })
  maxSelection: number;

  @Column({ type: 'int', default: 0 })
  sortOrder: number;

  @OneToMany(() => ExtraOption, (o) => o.group)
  options?: ExtraOption[];
}
