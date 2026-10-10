import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/controller/cart_controller.dart';
import 'package:lacarta/core/controller/order_controller.dart';
import 'package:lacarta/core/models/order.dart';

/// Formulario único para los tres tipos de pedido.
/// Cada tipo pide solo los campos que la API exige:
///  - Comer aquí: nombre + mesa
///  - Para llevar: nombre (+ teléfono opcional)
///  - Domicilio: nombre + teléfono + dirección
class OrderForm extends StatefulWidget {
  final String type;
  const OrderForm({super.key, required this.type});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _table = TextEditingController();
  final _notes = TextEditingController();

  final OrderController _orderController = Get.find<OrderController>();
  final CartController _cartController = Get.find<CartController>();

  bool get _isDelivery => widget.type == OrderType.delivery;
  bool get _isDineIn => widget.type == OrderType.dineIn;
  bool get _isTakeaway => widget.type == OrderType.takeaway;

  String get _title {
    if (_isDelivery) return 'Datos de entrega';
    if (_isDineIn) return 'Pedido en la mesa';
    return 'Pedido para recoger';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _table.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await _orderController.sendOrder(
      OrderCart(
        // Copia de la lista: el carrito se vacía si el pedido sale bien
        items: _cartController.cartItems.toList(),
        type: widget.type,
        customerName: _name.text,
        phone: _phone.text,
        address: _isDelivery ? _address.text : null,
        table: _isDineIn ? _table.text : null,
        notes: _notes.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        // Que el teclado no tape los campos
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: _isDelivery
                      ? 'Quién recibe'
                      : _isTakeaway
                          ? 'Nombre de quien recoge'
                          : 'Tu nombre',
                ),
                validator: (v) {
                  final err = _required(v, 'Escribe el nombre');
                  if (err != null) return err;
                  return v!.trim().length < 2 ? 'Nombre muy corto' : null;
                },
              ),
              if (_isDineIn)
                TextFormField(
                  controller: _table,
                  decoration: const InputDecoration(labelText: 'Número de mesa'),
                  validator: (v) => _required(v, 'Escribe el número de mesa'),
                ),
              if (!_isDineIn)
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _isDelivery ? 'Teléfono' : 'Teléfono (opcional)',
                  ),
                  validator: (v) =>
                      _isDelivery ? _required(v, 'Escribe el teléfono') : null,
                ),
              if (_isDelivery)
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  validator: (v) => _required(v, 'Escribe la dirección'),
                ),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notas para el restaurante (opcional)',
                ),
              ),
              const SizedBox(height: 15),
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total estimado'),
                      Text(
                        '\$ ${_cartController.totalCart.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  )),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final sending = _orderController.isSending.value;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColorBasic.blue1,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: sending ? null : _submit,
                    child: sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: CustomColorBasic.white1,
                            ),
                          )
                        : const Text(
                            'Confirmar pedido',
                            style: TextStyle(color: CustomColorBasic.white1),
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
