import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/constant/order_status.dart';
import 'package:lacarta/controller/cart_controller.dart';
import 'package:lacarta/controller/order_controller.dart';
import 'package:lacarta/models/order.dart';
class DeliveryForm extends StatelessWidget {

  final addressController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    final orderController = Get.find<OrderController>();
    final cartController = Get.find<CartController>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Text(
            "Datos de entrega",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Quien recibe"),
          ),

          TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: "Teléfono"),
          ),

          TextField(
            controller: addressController,
            decoration: const InputDecoration(labelText: "Dirección"),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width:double.infinity ,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColorBasic.blue1
              ),
              onPressed: () {
            
                orderController.saveOrder(
                  OrderCart(
                    items: cartController.cartItems,
                    status: OrderStatus.pending,
                    createdAt: DateTime.now(),
                    type: OrderType.delivery,
                    address: addressController.text,
                    customerName: nameController.text,
                    phone: phoneController.text,
                  )
                );
            
                Get.back();
            
              },
              child: const Text("Confirmar pedido", style: TextStyle(color: CustomColorBasic.white1),),
            ),
          )
        ],
      ),
    );
  }
}