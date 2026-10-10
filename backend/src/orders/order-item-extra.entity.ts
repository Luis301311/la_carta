import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { decimalTransformer } from '../common/decimal.transformer';
import { OrderItem } from './order-item.entity';

@Entity('order_item_extras')
export class OrderItemExtra {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  orderItemId: string;

  @ManyToOne(() => OrderItem, (i) => i.extras, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_item_id' })
  orderItem?: OrderItem;

  /** Referencia informativa (sin FK): la opción puede borrarse después */
  @Column('uuid', { nullable: true })
  optionId: string | null;

  @Column({ length: 100 })
  groupTitle: string;

  @Column({ length: 100 })
  optionName: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, transformer: decimalTransformer })
  unitPrice: number;

  @Column({ type: 'int', default: 1 })
  quantity: number;
}
