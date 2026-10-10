import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { Company } from './company.entity';

@Entity('business_hours')
@Unique(['companyId', 'dayOfWeek'])
export class BusinessHour {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  companyId: string;

  @ManyToOne(() => Company, (c) => c.businessHours, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'company_id' })
  company?: Company;

  /** 1 = lunes ... 7 = domingo (igual que DateTime.weekday en Dart) */
  @Column({ type: 'smallint' })
  dayOfWeek: number;

  /** "HH:mm" */
  @Column({ length: 5, default: '00:00' })
  openTime: string;

  /** "HH:mm". Si es menor o igual que openTime, cierra al día siguiente (p. ej. 18:00–02:00) */
  @Column({ length: 5, default: '00:00' })
  closeTime: string;

  @Column({ default: false })
  closed: boolean;
}
