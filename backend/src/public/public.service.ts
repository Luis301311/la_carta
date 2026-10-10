import { Injectable } from '@nestjs/common';
import { CategoriesService } from '../categories/categories.service';
import { CompaniesService } from '../companies/companies.service';
import { isOpenNow } from '../companies/opening-hours';
import { CreateOrderDto } from '../orders/dto/order.dto';
import { OrdersService } from '../orders/orders.service';
import { ProductsService } from '../products/products.service';

@Injectable()
export class PublicService {
  constructor(
    private readonly companies: CompaniesService,
    private readonly categories: CategoriesService,
    private readonly products: ProductsService,
    private readonly orders: OrdersService,
  ) {}

  /** Todo lo que necesita la app del cliente en UNA sola petición */
  async getMenu(slug: string) {
    const company = await this.companies.findActiveBySlug(slug);
    const [categories, products] = await Promise.all([
      this.categories.findAll(company.id, true),
      this.products.findAll(company.id, { onlyAvailable: true }),
    ]);

    // Oculta opciones desactivadas y grupos que quedaron sin opciones
    const cleanProducts = products.map((p) => ({
      ...p,
      extraGroups: (p.extraGroups ?? [])
        .map((g) => ({ ...g, options: (g.options ?? []).filter((o) => o.isActive) }))
        .filter((g) => g.options.length > 0),
    }));

    const byCategory = new Map<string, typeof cleanProducts>();
    for (const p of cleanProducts) {
      const list = byCategory.get(p.categoryId) ?? [];
      list.push(p);
      byCategory.set(p.categoryId, list);
    }

    return {
      company: {
        id: company.id,
        name: company.name,
        slug: company.slug,
        phone: company.phone,
        whatsappPhone: company.whatsappPhone,
        email: company.email,
        address: company.address,
        latitude: company.latitude,
        longitude: company.longitude,
        logoUrl: company.logoUrl,
        coverUrl: company.coverUrl,
        primaryColor: company.primaryColor,
        timezone: company.timezone,
        businessHours: company.businessHours ?? [],
        isOpenNow: isOpenNow(company.businessHours ?? [], company.timezone),
      },
      categories: categories
        .map((c) => ({
          id: c.id,
          name: c.name,
          description: c.description,
          imageUrl: c.imageUrl,
          sortOrder: c.sortOrder,
          products: byCategory.get(c.id) ?? [],
        }))
        .filter((c) => c.products.length > 0),
    };
  }

  async createOrder(slug: string, dto: CreateOrderDto) {
    const company = await this.companies.findActiveBySlug(slug);
    const order = await this.orders.create(company.id, dto);
    return {
      order,
      // Para que Flutter abra WhatsApp con el pedido ya armado
      whatsappUrl: company.whatsappPhone
        ? `https://wa.me/${company.whatsappPhone}?text=${encodeURIComponent(buildWhatsappText(company.name, order))}`
        : null,
    };
  }
}

const money = (n: number) => '$' + Math.round(n).toLocaleString('es-CO');
const TYPE_LABEL: Record<string, string> = {
  dine_in: 'Comer en el sitio',
  takeaway: 'Para llevar',
  delivery: 'Domicilio',
};

function buildWhatsappText(companyName: string, order: Awaited<ReturnType<OrdersService['findOne']>>) {
  const lines = [`*Pedido #${order.orderNumber} - ${companyName}*`, ''];
  for (const item of order.items ?? []) {
    lines.push(`${item.quantity} x ${item.productName} - ${money(item.lineTotal)}`);
    for (const e of item.extras ?? []) {
      lines.push(`   + ${e.quantity > 1 ? e.quantity + ' x ' : ''}${e.optionName}`);
    }
    if (item.comment) lines.push(`   _${item.comment}_`);
  }
  lines.push('', `*Total: ${money(order.total)}*`, `Tipo: ${TYPE_LABEL[order.type] ?? order.type}`);
  lines.push(`Nombre: ${order.customerName}`);
  if (order.phone) lines.push(`Teléfono: ${order.phone}`);
  if (order.address) lines.push(`Dirección: ${order.address}`);
  if (order.tableNumber) lines.push(`Mesa: ${order.tableNumber}`);
  if (order.notes) lines.push(`Notas: ${order.notes}`);
  return lines.join('\n');
}
