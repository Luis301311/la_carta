import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { BusinessHour } from './business-hour.entity';

/** Una empresa = un restaurante con su propio menú (antes: `restaurants`). */
@Entity('companies')
export class Company {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 120 })
  name: string;

  /** Parte de la URL del menú: lacarta.app/burger_house */
  @Index({ unique: true })
  @Column({ length: 80 })
  slug: string;

  @Column({ type: 'varchar', length: 40, nullable: true })
  taxId: string | null; // NIT

  @Column({ type: 'varchar', length: 30, nullable: true })
  phone: string | null;

  /** Número al que se envían los pedidos por WhatsApp (con indicativo, p. ej. 573001234567) */
  @Column({ type: 'varchar', length: 30, nullable: true })
  whatsappPhone: string | null;

  @Column({ type: 'varchar', length: 160, nullable: true })
  email: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  address: string | null;

  @Column({ type: 'double precision', nullable: true })
  latitude: number | null;

  @Column({ type: 'double precision', nullable: true })
  longitude: number | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  logoUrl: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  coverUrl: string | null;

  /** Color principal del menú en hex, p. ej. #E53935 */
  @Column({ type: 'varchar', length: 9, nullable: true })
  primaryColor: string | null;

  /** Zona horaria para calcular si está abierto */
  @Column({ length: 60, default: 'America/Bogota' })
  timezone: string;

  // ---------- Pagos (sin pasarela) ----------

  @Column({ default: true })
  acceptsCash: boolean;

  /** Transferencia por QR o llave Bre-B; se verifica con el comprobante */
  @Column({ default: false })
  acceptsTransfer: boolean;

  /** Llave Bre-B (celular, cédula, correo o alfanumérica) */
  @Column({ type: 'varchar', length: 80, nullable: true })
  breBKey: string | null;

  /** Nombre del titular de la cuenta, para que el cliente verifique */
  @Column({ type: 'varchar', length: 120, nullable: true })
  paymentHolder: string | null;

  /** Imagen del código QR de cobro (la genera la app del banco) */
  @Column({ type: 'varchar', length: 500, nullable: true })
  paymentQrUrl: string | null;

  /** Instrucciones extra, p. ej. "También Nequi 300 123 4567" */
  @Column({ type: 'text', nullable: true })
  paymentNotes: string | null;

  /** false = suspendida por el super admin: el menú no se muestra y su admin no puede entrar */
  @Column({ default: true })
  isActive: boolean;

  @OneToMany(() => BusinessHour, (h) => h.company)
  businessHours?: BusinessHour[];

  @OneToMany(() => User, (u) => u.company)
  users?: User[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
