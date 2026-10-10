import 'package:flutter/material.dart';

class OrderStatus {
  static const pending = "pending"; // pedido creado
  static const confirmed = "confirmed"; // aceptado por el restaurante
  static const preparing = "preparing"; // en cocina
  static const ready = "ready"; // listo para entregar
  static const delivered = "delivered"; // entregado al cliente
  static const cancelled = "cancelled"; // cancelado

  static const all = [pending, confirmed, preparing, ready, delivered, cancelled];

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Por confirmar';
      case confirmed:
        return 'Confirmado';
      case preparing:
        return 'Preparando';
      case ready:
        return 'Listo';
      case delivered:
        return 'Entregado';
      case cancelled:
        return 'Cancelado';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status) {
      case pending:
        return Colors.orange;
      case confirmed:
        return Colors.blue;
      case preparing:
        return Colors.deepPurple;
      case ready:
        return Colors.teal;
      case delivered:
        return Colors.green;
      case cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Siguiente paso "normal" (el botón principal del pedido).
  /// Mismas reglas que la API.
  static String? next(String status) {
    switch (status) {
      case pending:
        return confirmed;
      case confirmed:
        return preparing;
      case preparing:
        return ready;
      case ready:
        return delivered;
      default:
        return null;
    }
  }

  /// Paso anterior (para corregir un error). Mismas reglas que la API.
  static String? previous(String status) {
    switch (status) {
      case confirmed:
        return pending;
      case preparing:
        return confirmed;
      case ready:
        return preparing;
      case delivered:
        return ready;
      default:
        return null;
    }
  }

  /// Texto del botón para avanzar
  static String actionLabel(String nextStatus) {
    switch (nextStatus) {
      case confirmed:
        return 'Confirmar';
      case preparing:
        return 'A cocina';
      case ready:
        return 'Marcar listo';
      case delivered:
        return 'Entregado';
      default:
        return label(nextStatus);
    }
  }

  static bool canCancel(String status) =>
      status != delivered && status != cancelled;
}

/// Formas de pago sin pasarela (mismos valores que la API)
class PaymentMethod {
  static const cash = 'cash';
  static const transfer = 'transfer';

  static String label(String method) =>
      method == transfer ? 'Transferencia' : 'Efectivo';

  static IconData icon(String method) =>
      method == transfer ? Icons.qr_code_2 : Icons.payments_outlined;
}

class OrderType {
  static const dineIn = "dine_in"; // comer en el sitio
  static const takeaway = "takeaway"; // para llevar
  static const delivery = "delivery"; // domicilio

  static String label(String type) {
    switch (type) {
      case dineIn:
        return 'En el sitio';
      case takeaway:
        return 'Para llevar';
      case delivery:
        return 'Domicilio';
      default:
        return type;
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case dineIn:
        return Icons.restaurant;
      case takeaway:
        return Icons.shopping_bag;
      case delivery:
        return Icons.delivery_dining;
      default:
        return Icons.receipt;
    }
  }
}
