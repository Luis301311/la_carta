export enum Role {
  SUPER_ADMIN = 'SUPER_ADMIN',
  COMPANY_ADMIN = 'COMPANY_ADMIN',
}

/** Mismos valores que lib/core/constant/order_status.dart en Flutter */
export enum OrderStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  PREPARING = 'preparing',
  READY = 'ready',
  DELIVERED = 'delivered',
  CANCELLED = 'cancelled',
}

/** Sin pasarela: la transferencia (QR o llave Bre-B) se verifica a mano con el comprobante */
export enum PaymentMethod {
  CASH = 'cash',
  TRANSFER = 'transfer',
}

export enum OrderType {
  DINE_IN = 'dine_in',
  TAKEAWAY = 'takeaway',
  DELIVERY = 'delivery',
}
