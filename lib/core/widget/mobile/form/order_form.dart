import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/menu_brand.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/controller/cart_controller.dart';
import 'package:lacarta/core/controller/company_controller.dart';
import 'package:lacarta/core/controller/order_controller.dart';
import 'package:lacarta/core/models/order.dart';
import 'package:lacarta/core/widget/mobile/form/payment_section.dart';

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
  final RestaurantController _restaurant = Get.find<RestaurantController>();

  late String _payment;
  PaymentProof? _proof;
  bool _showProofError = false;

  @override
  void initState() {
    super.initState();
    final company = _restaurant.company.value;
    // Efectivo por defecto si lo aceptan; si no, transferencia
    _payment = (company == null || company.acceptsCash)
        ? PaymentMethod.cash
        : PaymentMethod.transfer;
  }

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
    final formOk = _formKey.currentState!.validate();
    final needsProof = _payment == PaymentMethod.transfer && _proof == null;
    if (needsProof != _showProofError) {
      setState(() => _showProofError = needsProof);
    }
    if (!formOk || needsProof) return;

    await _orderController.sendOrder(
      proof: _payment == PaymentMethod.transfer ? _proof?.bytes : null,
      proofName: _proof?.name ?? 'comprobante.jpg',
      OrderCart(
        // Copia de la lista: el carrito se vacía si el pedido sale bien
        items: _cartController.cartItems.toList(),
        type: widget.type,
        customerName: _name.text,
        phone: _phone.text,
        address: _isDelivery ? _address.text : null,
        table: _isDineIn ? _table.text : null,
        notes: _notes.text,
        paymentMethod: _payment,
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
              // Obligatorio en todos los pedidos: por aquí el restaurante
              // avisa cuando confirma el pago y cuando el pedido está listo
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Celular (WhatsApp)',
                  helperText: 'Te avisaremos por aquí cuando tu pedido esté listo',
                ),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.isEmpty) return 'Escribe tu celular';
                  if (digits.length < 7) return 'Número no válido';
                  return null;
                },
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
              const SizedBox(height: 18),
              // Forma de pago (solo las que acepta el restaurante)
              Builder(builder: (context) {
                final company = _restaurant.company.value;
                if (company == null) return const SizedBox.shrink();
                return PaymentSection(
                  company: company,
                  method: _payment,
                  onMethodChanged: (m) => setState(() {
                    _payment = m;
                    _showProofError = false;
                  }),
                  total: _cartController.totalCart,
                  proof: _proof,
                  onProofChanged: (p) => setState(() {
                    _proof = p;
                    if (p != null) _showProofError = false;
                  }),
                  showProofError: _showProofError,
                );
              }),
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
                      backgroundColor: MenuBrand.color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: sending ? null : _submit,
                    child: sending
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: MenuBrand.onColor,
                            ),
                          )
                        : Text(
                            'Confirmar pedido',
                            style: TextStyle(color: MenuBrand.onColor),
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
