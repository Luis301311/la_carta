import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { decimalTransformer } from '../common/decimal.transformer';
import { ExtraGroup } from './extra-group.entity';

/** Ej.: "Salsa de ajo" +$1.000 */
@Entity('extra_options')
export class ExtraOption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  groupId: string;

  @ManyToOne(() => ExtraGroup, (g) => g.options, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'group_id' })
  group?: ExtraGroup;

  @Column({ length: 100 })
  name: string;

  @Column({
    type: 'numeric',
    precision: 12,
    scale: 2,
    default: 0,
    transformer: decimalTransformer,
  })
  price: number;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'int', default: 0 })
  sortOrder: number;
}
