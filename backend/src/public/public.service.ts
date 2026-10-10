import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { mkdirSync, writeFileSync } from 'fs';
import { join, resolve } from 'path';
import { CategoriesService } from '../categories/categories.service';
import { PaymentMethod } from '../common/enums';
import { CompaniesService } from '../companies/companies.service';
import { Company } from '../companies/company.entity';
import { isOpenNow } from '../companies/opening-hours';
import { CreateOrderDto } from '../orders/dto/order.dto';
import { Order } from '../orders/order.entity';
import { OrdersService } from '../orders/orders.service';
import { ProductsService } from '../products/products.service';

const IMAGE_EXT: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
};

@Injectable()
export class PublicService {
  constructor(
    private readonly companies: CompaniesService,
    private readonly categories: CategoriesService,
    private readonly products: ProductsService,
    private readonly orders: OrdersService,
    private readonly config: ConfigService,
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
        // Pagos
        acceptsCash: company.acceptsCash,
        acceptsTransfer: company.acceptsTransfer,
        breBKey: company.acceptsTransfer ? company.breBKey : null,
        paymentHolder: company.acceptsTransfer ? company.paymentHolder : null,
        paymentQrUrl: company.acceptsTransfer ? company.paymentQrUrl : null,
        paymentNotes: company.paymentNotes,
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

  /**
   * Crea el pedido. Si es por transferencia, devuelve `proofToken`: la app lo
   * usa enseguida para subir el comprobante (POST .../orders/:id/proof).
   */
  async createOrder(slug: string, dto: CreateOrderDto) {
    const company = await this.companies.findActiveBySlug(slug);
    const { order, proofToken } = await this.orders.create(company.id, dto);
    return {
      order,
      proofToken,
      whatsappUrl: this.whatsappUrl(company, order),
    };
  }

  /** El cliente adjunta la captura del pago (sin login, con su proofToken) */
  async attachProof(
    slug: string,
    orderId: string,
    token: string,
    file: Express.Multer.File | undefined,
  ) {
    if (!file) throw new BadRequestException('Envía la imagen en el campo "file"');
    const ext = IMAGE_EXT[file.mimetype];
    if (!ext) throw new BadRequestException('El comprobante debe ser una imagen');

    const company = await this.companies.findActiveBySlug(slug);
    await this.orders.assertCanAttachProof(company.id, orderId, token);

    // Se guarda en disco solo después de validar la clave
    const dir = join(resolve(process.env.UPLOAD_DIR ?? 'uploads'), company.id, 'proofs');
    mkdirSync(dir, { recursive: true });
    const filename = `${randomUUID()}${ext}`;
    writeFileSync(join(dir, filename), file.buffer);

    const base = (this.config.get<string>('PUBLIC_URL') ?? 'http://localhost:3000').replace(/\/$/, '');
    const order = await this.orders.setPaymentProof(
      company.id,
      orderId,
      `${base}/uploads/${company.id}/proofs/${filename}`,
    );
    return { order, whatsappUrl: this.whatsappUrl(company, order) };
  }

  private whatsappUrl(company: Company, order: Order) {
    return company.whatsappPhone
      ? `https://wa.me/${company.whatsappPhone}?text=${encodeURIComponent(buildWhatsappText(company.name, order))}`
      : null;
  }
}

const money = (n: number) => '$' + Math.round(n).toLocaleString('es-CO');
const TYPE_LABEL: Record<string, string> = {
  dine_in: 'Comer en el sitio',
  takeaway: 'Para llevar',
  delivery: 'Domicilio',
};

function buildWhatsappText(companyName: string, order: Order) {
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

  lines.push('');
  if (order.paymentMethod === PaymentMethod.TRANSFER) {
    lines.push(
      order.paymentProofUrl
        ? '*Pago:* Transferencia — el comprobante quedó adjunto al pedido ✅'
        : '*Pago:* Transferencia — te envío el comprobante por este chat 📎',
    );
  } else {
    lines.push('*Pago:* Efectivo');
  }
  lines.push('Quedo atento a la confirmación 🙌');
  return lines.join('\n');
}
