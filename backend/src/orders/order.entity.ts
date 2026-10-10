import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  Unique,
  UpdateDateColumn,
} from 'typeorm';
import { decimalTransformer } from '../common/decimal.transformer';
import { OrderStatus, OrderType, PaymentMethod } from '../common/enums';
import { Company } from '../companies/company.entity';
import { OrderItem } from './order-item.entity';

@Entity('orders')
@Unique(['companyId', 'orderNumber'])
@Index(['companyId', 'createdAt'])
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  companyId: string;

  @ManyToOne(() => Company, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'company_id' })
  company?: Company;

  /** Consecutivo por empresa: Pedido #1, #2, ... */
  @Column({ type: 'int' })
  orderNumber: number;

  @Column({
    type: 'enum',
    enum: OrderStatus,
    enumName: 'order_status',
    default: OrderStatus.PENDING,
  })
  status: OrderStatus;

  @Column({ type: 'enum', enum: OrderType, enumName: 'order_type' })
  type: OrderType;

  @Column({ length: 120 })
  customerName: string;

  @Column({ type: 'varchar', length: 30, nullable: true })
  phone: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  address: string | null;

  @Column({ type: 'varchar', length: 20, nullable: true })
  tableNumber: string | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    enumName: 'payment_method',
    default: PaymentMethod.CASH,
  })
  paymentMethod: PaymentMethod;

  /** Captura del comprobante de transferencia que sube el cliente */
  @Column({ type: 'varchar', length: 500, nullable: true })
  paymentProofUrl: string | null;

  /**
   * Clave de un solo uso que recibe el cliente al crear el pedido, para poder
   * subir su comprobante sin iniciar sesión. Nunca se devuelve en consultas.
   */
  @Column({ type: 'varchar', length: 64, nullable: true, select: false })
  proofToken: string | null;

  @Column({ type: 'numeric', precision: 12, scale: 2, transformer: decimalTransformer })
  total: number;

  @OneToMany(() => OrderItem, (i) => i.order)
  items?: OrderItem[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
