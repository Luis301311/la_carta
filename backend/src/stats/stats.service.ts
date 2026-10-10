import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { OrderStatus } from '../common/enums';
import { Company } from '../companies/company.entity';
import { Order } from '../orders/order.entity';
import { Product } from '../products/product.entity';

/** Zona horaria válida para Postgres (si no, Bogotá) */
function safeTimezone(tz: string | null | undefined) {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz ?? undefined });
    return tz || 'America/Bogota';
  } catch {
    return 'America/Bogota';
  }
}

@Injectable()
export class StatsService {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  /**
   * Todo lo que muestra el inicio del panel en una sola petición.
   * Los días se calculan en la zona horaria del restaurante (no en UTC),
   * así "hoy" empieza a medianoche de Colombia.
   *
   * - Ventas: pedidos confirmados o más adelante (no cuenta "por confirmar"
   *   ni cancelados, porque ese dinero todavía no es seguro).
   * - Pedidos: todos menos los cancelados.
   */
  async dashboard(companyId: string) {
    const company = await this.dataSource
      .getRepository(Company)
      .findOne({ where: { id: companyId } });
    if (!company) throw new NotFoundException('Empresa no encontrada');
    const tz = safeTimezone(company.timezone);

    // 14 días: esta semana (últimos 7) y la anterior, para la tendencia
    const rows: { day: string; sales: string; orders: string }[] =
      await this.dataSource.query(
        `WITH t AS (SELECT (now() AT TIME ZONE $2)::date AS today)
         SELECT to_char(d, 'YYYY-MM-DD') AS day,
                COALESCE(SUM(o.total) FILTER (
                  WHERE o.status NOT IN ('${OrderStatus.PENDING}', '${OrderStatus.CANCELLED}')
                ), 0) AS sales,
                COUNT(o.id) FILTER (WHERE o.status <> '${OrderStatus.CANCELLED}') AS orders
         FROM t, generate_series(t.today - 13, t.today, interval '1 day') AS d
         LEFT JOIN orders o
           ON o.company_id = $1
          AND (o.created_at AT TIME ZONE $2)::date = d::date
         GROUP BY d
         ORDER BY d`,
        [companyId, tz],
      );
    const days = rows.map((r) => ({
      date: r.day,
      sales: Number(r.sales),
      orders: Number(r.orders),
    }));
    const week = days.slice(7);
    const previousWeek = days.slice(0, 7);
    const sum = (list: typeof days) => list.reduce((s, d) => s + d.sales, 0);
    const weekTotal = sum(week);
    const previousWeekTotal = sum(previousWeek);
    const today = week[week.length - 1];
    const yesterday = week[week.length - 2];

    const orders = this.dataSource.getRepository(Order);
    const [pending, recent, productTotals] = await Promise.all([
      orders.count({ where: { companyId, status: OrderStatus.PENDING } }),
      orders.find({
        where: { companyId },
        relations: { items: true },
        order: { createdAt: 'DESC' },
        take: 6,
      }),
      this.dataSource
        .getRepository(Product)
        .createQueryBuilder('p')
        .select('COUNT(*)', 'total')
        .addSelect('COUNT(*) FILTER (WHERE p.is_available)', 'available')
        .where('p.company_id = :companyId', { companyId })
        .getRawOne<{ total: string; available: string }>(),
    ]);

    const pct = (now: number, before: number) =>
      before > 0 ? Math.round(((now - before) / before) * 100) : null;

    return {
      timezone: tz,
      today: {
        date: today?.date ?? null,
        orders: today?.orders ?? 0,
        sales: today?.sales ?? 0,
        pending,
        // vs. ayer (null si ayer no hubo ventas)
        salesTrendPct: pct(today?.sales ?? 0, yesterday?.sales ?? 0),
      },
      week,
      weekTotal,
      previousWeekTotal,
      weekTrendPct: pct(weekTotal, previousWeekTotal),
      products: {
        total: Number(productTotals?.total ?? 0),
        available: Number(productTotals?.available ?? 0),
      },
      recentOrders: recent.map((o) => ({
        id: o.id,
        orderNumber: o.orderNumber,
        status: o.status,
        type: o.type,
        customerName: o.customerName,
        total: o.total,
        createdAt: o.createdAt,
        units: (o.items ?? []).reduce((s, i) => s + i.quantity, 0),
      })),
    };
  }
}
