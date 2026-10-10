import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { Between, DataSource, FindOptionsWhere, In, LessThanOrEqual, MoreThanOrEqual, Repository } from 'typeorm';
import { OrderStatus, OrderType, PaymentMethod } from '../common/enums';
import { round2 } from '../common/money';
import { Company } from '../companies/company.entity';
import { ExtraGroup } from '../products/extra-group.entity';
import { ExtraOption } from '../products/extra-option.entity';
import { Product } from '../products/product.entity';
import { CreateOrderDto, ListOrdersQueryDto } from './dto/order.dto';
import { OrderItemExtra } from './order-item-extra.entity';
import { OrderItem } from './order-item.entity';
import { Order } from './order.entity';

/**
 * Cambios de estado permitidos. Además del avance normal, se puede volver
 * UN paso atrás para corregir un error (p. ej. marcar "listo" el pedido
 * equivocado). Cancelado es definitivo.
 */
const TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PENDING]: [OrderStatus.CONFIRMED, OrderStatus.PREPARING, OrderStatus.CANCELLED],
  [OrderStatus.CONFIRMED]: [OrderStatus.PREPARING, OrderStatus.CANCELLED, OrderStatus.PENDING],
  [OrderStatus.PREPARING]: [OrderStatus.READY, OrderStatus.CANCELLED, OrderStatus.CONFIRMED],
  [OrderStatus.READY]: [OrderStatus.DELIVERED, OrderStatus.CANCELLED, OrderStatus.PREPARING],
  [OrderStatus.DELIVERED]: [OrderStatus.READY],
  [OrderStatus.CANCELLED]: [],
};

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order) private readonly repo: Repository<Order>,
    @InjectDataSource() private readonly dataSource: DataSource,
  ) {}

  /**
   * Crea un pedido desde el menú público. Valida productos, extras y reglas
   * de cada grupo (mín/máx) y calcula los precios en el servidor.
   */
  async create(
    companyId: string,
    dto: CreateOrderDto,
  ): Promise<{ order: Order; proofToken: string | null }> {
    this.validateByType(dto);

    // El método de pago debe estar activo en ESE restaurante
    const paymentMethod = dto.paymentMethod ?? PaymentMethod.CASH;
    const company = await this.dataSource
      .getRepository(Company)
      .findOne({ where: { id: companyId } });
    if (!company) throw new NotFoundException('Restaurante no encontrado');
    if (paymentMethod === PaymentMethod.CASH && !company.acceptsCash) {
      throw new BadRequestException('Este restaurante no recibe pagos en efectivo');
    }
    if (paymentMethod === PaymentMethod.TRANSFER && !company.acceptsTransfer) {
      throw new BadRequestException('Este restaurante no recibe transferencias');
    }
    // Clave para que el cliente suba su comprobante sin iniciar sesión
    const proofToken =
      paymentMethod === PaymentMethod.TRANSFER ? randomBytes(24).toString('hex') : null;

    const productIds = [...new Set(dto.items.map((i) => i.productId))];
    const products: Product[] = await this.dataSource.getRepository(Product).find({
      where: { id: In(productIds), companyId },
      relations: { extraGroups: { options: true } },
    });
    const productMap = new Map<string, Product>(products.map((p) => [p.id, p]));

    let total = 0;
    const lines = dto.items.map((input) => {
      const product = productMap.get(input.productId);
      if (!product) throw new BadRequestException('Un producto del pedido no existe en este menú');
      if (!product.isAvailable) throw new BadRequestException(`"${product.name}" no está disponible`);

      // opción -> grupo, solo opciones activas de ESTE producto
      const optionIndex = new Map<string, { group: ExtraGroup; option: ExtraOption }>();
      for (const group of product.extraGroups ?? []) {
        for (const option of group.options ?? []) {
          if (option.isActive) optionIndex.set(option.id, { group, option });
        }
      }

      const perGroupCount = new Map<string, number>();
      const extras = (input.extras ?? []).map((e) => {
        const found = optionIndex.get(e.optionId);
        if (!found) {
          throw new BadRequestException(`Una adición no es válida para "${product.name}"`);
        }
        const qty = e.quantity ?? 1;
        perGroupCount.set(found.group.id, (perGroupCount.get(found.group.id) ?? 0) + qty);
        return {
          optionId: found.option.id,
          groupTitle: found.group.title,
          optionName: found.option.name,
          unitPrice: Number(found.option.price),
          quantity: qty,
        };
      });

      for (const group of product.extraGroups ?? []) {
        const n = perGroupCount.get(group.id) ?? 0;
        const min = group.isRequired ? Math.max(1, group.minSelection) : group.minSelection;
        if (n < min) {
          throw new BadRequestException(`"${product.name}": elige al menos ${min} en "${group.title}"`);
        }
        if (n > group.maxSelection) {
          throw new BadRequestException(`"${product.name}": máximo ${group.maxSelection} en "${group.title}"`);
        }
      }

      const extrasTotal = round2(extras.reduce((s, e) => s + e.unitPrice * e.quantity, 0));
      const unitPrice = Number(product.basePrice);
      const lineTotal = round2(input.quantity * (unitPrice + extrasTotal));
      total = round2(total + lineTotal);

      return {
        productId: product.id,
        productName: product.name,
        unitPrice,
        quantity: input.quantity,
        extrasTotal,
        lineTotal,
        comment: input.comment?.trim() || null,
        extras,
      };
    });

    const orderId = await this.dataSource.transaction(async (manager) => {
      // Bloquea la fila de la empresa para que el consecutivo no se repita con pedidos simultáneos
      await manager
        .getRepository(Company)
        .createQueryBuilder('c')
        .setLock('pessimistic_write')
        .where('c.id = :companyId', { companyId })
        .getOne();
      const { max } = await manager
        .getRepository(Order)
        .createQueryBuilder('o')
        .select('COALESCE(MAX(o.order_number), 0)', 'max')
        .where('o.company_id = :companyId', { companyId })
        .getRawOne();

      const order = await manager.save(
        manager.create(Order, {
          companyId,
          orderNumber: Number(max) + 1,
          status: OrderStatus.PENDING,
          type: dto.type,
          customerName: dto.customerName.trim(),
          phone: dto.phone?.trim() || null,
          address: dto.address?.trim() || null,
          tableNumber: dto.tableNumber?.trim() || null,
          notes: dto.notes?.trim() || null,
          paymentMethod,
          proofToken,
          total,
        }),
      );

      for (const line of lines) {
        const { extras, ...itemData } = line;
        const item = await manager.save(manager.create(OrderItem, { ...itemData, orderId: order.id }));
        if (extras.length) {
          await manager.insert(
            OrderItemExtra,
            extras.map((e) => ({ ...e, orderItemId: item.id })),
          );
        }
      }
      return order.id;
    });

    return { order: await this.findOne(companyId, orderId), proofToken };
  }

  /**
   * Guarda la URL del comprobante de un pedido por transferencia.
   * Se valida con la clave que recibió el cliente al crear el pedido.
   * Mientras el pedido siga pendiente, puede reemplazar el comprobante.
   */
  async assertCanAttachProof(companyId: string, orderId: string, token: string) {
    const order = await this.repo
      .createQueryBuilder('o')
      .addSelect('o.proofToken')
      .where('o.id = :orderId AND o.company_id = :companyId', { orderId, companyId })
      .getOne();
    if (!order) throw new NotFoundException('Pedido no encontrado');
    if (!order.proofToken || !token || order.proofToken !== token) {
      throw new ForbiddenException('No puedes adjuntar un comprobante a este pedido');
    }
    if (order.status !== OrderStatus.PENDING) {
      throw new BadRequestException('El pedido ya fue procesado');
    }
    return order;
  }

  async setPaymentProof(companyId: string, orderId: string, url: string) {
    await this.repo.update({ id: orderId, companyId }, { paymentProofUrl: url });
    return this.findOne(companyId, orderId);
  }

  async findAll(companyId: string, q: ListOrdersQueryDto) {
    const page = q.page ?? 1;
    const limit = q.limit ?? 20;
    const where: FindOptionsWhere<Order> = { companyId };
    if (q.status) where.status = q.status;

    const from = q.from ? new Date(q.from) : undefined;
    // "to" con solo fecha (2026-10-31) incluye todo ese día
    const to = q.to
      ? new Date(q.to.length === 10 ? `${q.to}T23:59:59.999Z` : q.to)
      : undefined;
    if (from && to) where.createdAt = Between(from, to);
    else if (from) where.createdAt = MoreThanOrEqual(from);
    else if (to) where.createdAt = LessThanOrEqual(to);

    const [data, total] = await this.repo.findAndCount({
      where,
      relations: { items: { extras: true } },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { data, total, page, limit, pages: Math.ceil(total / limit) };
  }

  /**
   * Consulta muy liviana para saber si algo cambió (pedido nuevo, cambio de
   * estado, comprobante). Las pantallas del panel la llaman cada pocos
   * segundos y solo descargan los pedidos cuando la respuesta cambia.
   */
  async lastChange(companyId: string) {
    const row = await this.repo
      .createQueryBuilder('o')
      .select('MAX(o.updated_at)', 'last')
      .addSelect('COUNT(*)', 'count')
      .where('o.company_id = :companyId', { companyId })
      .getRawOne<{ last: Date | string | null; count: string }>();
    const last = row?.last ? new Date(row.last).toISOString() : null;
    const count = Number(row?.count ?? 0);
    return { lastChange: last, count, version: `${last ?? '0'}|${count}` };
  }

  async findOne(companyId: string, id: string) {
    const order = await this.repo.findOne({
      where: { id, companyId },
      relations: { items: { extras: true } },
    });
    if (!order) throw new NotFoundException('Pedido no encontrado');
    return order;
  }

  async updateStatus(companyId: string, id: string, status: OrderStatus) {
    const order = await this.repo.findOne({ where: { id, companyId } });
    if (!order) throw new NotFoundException('Pedido no encontrado');
    if (order.status === status) return this.findOne(companyId, id);
    if (!TRANSITIONS[order.status].includes(status)) {
      throw new BadRequestException(`No se puede pasar de "${order.status}" a "${status}"`);
    }
    await this.repo.update({ id, companyId }, { status });
    return this.findOne(companyId, id);
  }

  private validateByType(dto: CreateOrderDto) {
    // El teléfono es obligatorio siempre: el restaurante avisa por WhatsApp
    // cuando confirma el pago y cuando el pedido está listo
    const digits = (dto.phone ?? '').replace(/\D/g, '');
    if (digits.length < 7) {
      throw new BadRequestException('Escribe un número de celular válido (WhatsApp)');
    }
    if (dto.type === OrderType.DELIVERY && (!dto.address?.trim() || !dto.phone?.trim())) {
      throw new BadRequestException('Para domicilio se necesitan dirección y teléfono');
    }
    if (dto.type === OrderType.DINE_IN && !dto.tableNumber?.trim()) {
      throw new BadRequestException('Para comer en el sitio se necesita el número de mesa');
    }
  }
}
