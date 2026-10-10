import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { decimalTransformer } from '../common/decimal.transformer';
import { Product } from '../products/product.entity';
import { OrderItemExtra } from './order-item-extra.entity';
import { Order } from './order.entity';

/**
 * Guarda una "foto" del producto (nombre y precio) al momento del pedido,
 * para que el histórico no cambie si luego editas o borras el producto.
 */
@Entity('order_items')
export class OrderItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  orderId: string;

  @ManyToOne(() => Order, (o) => o.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order?: Order;

  @Column('uuid', { nullable: true })
  productId: string | null;

  @ManyToOne(() => Product, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'product_id' })
  product?: Product | null;

  @Column({ length: 150 })
  productName: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, transformer: decimalTransformer })
  unitPrice: number;

  @Column({ type: 'int' })
  quantity: number;

  /** Suma de extras por unidad */
  @Column({ type: 'numeric', precision: 12, scale: 2, transformer: decimalTransformer })
  extrasTotal: number;

  /** quantity * (unitPrice + extrasTotal) */
  @Column({ type: 'numeric', precision: 12, scale: 2, transformer: decimalTransformer })
  lineTotal: number;

  @Column({ type: 'text', nullable: true })
  comment: string | null;

  @OneToMany(() => OrderItemExtra, (e) => e.orderItem)
  extras?: OrderItemExtra[];
}
