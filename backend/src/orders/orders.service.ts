import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { Between, DataSource, FindOptionsWhere, In, LessThanOrEqual, MoreThanOrEqual, Repository } from 'typeorm';
import { OrderStatus, OrderType } from '../common/enums';
import { round2 } from '../common/money';
import { Company } from '../companies/company.entity';
import { ExtraGroup } from '../products/extra-group.entity';
import { ExtraOption } from '../products/extra-option.entity';
import { Product } from '../products/product.entity';
import { CreateOrderDto, ListOrdersQueryDto } from './dto/order.dto';
import { OrderItemExtra } from './order-item-extra.entity';
import { OrderItem } from './order-item.entity';
import { Order } from './order.entity';

/** Cambios de estado permitidos */
const TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PENDING]: [OrderStatus.CONFIRMED, OrderStatus.PREPARING, OrderStatus.CANCELLED],
  [OrderStatus.CONFIRMED]: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
  [OrderStatus.PREPARING]: [OrderStatus.READY, OrderStatus.CANCELLED],
  [OrderStatus.READY]: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
  [OrderStatus.DELIVERED]: [],
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
  async create(companyId: string, dto: CreateOrderDto) {
    this.validateByType(dto);

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
    if (dto.type === OrderType.DELIVERY && (!dto.address?.trim() || !dto.phone?.trim())) {
      throw new BadRequestException('Para domicilio se necesitan dirección y teléfono');
    }
    if (dto.type === OrderType.DINE_IN && !dto.tableNumber?.trim()) {
      throw new BadRequestException('Para comer en el sitio se necesita el número de mesa');
    }
  }
}
