import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/controller/cart_controller.dart';

class CartPage extends StatelessWidget {
  CartPage({super.key});

  final CartController cartController = Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.blue,
        ),
        title: const Text("Pedido"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: cartController.clearCart, color: CustomColorBasic.black1,
          ),
        ],
      ),
      body: Obx(() {
        if (cartController.cartItems.isEmpty) {
          return const Center(
            child: Text("El pedido está vacío"),
          );
        }

        return Column(
          children: [

            /// 🛒 Lista de productos
            Expanded(
              child: ListView.builder(
                itemCount: cartController.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartController.cartItems[index];

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [

                          /// Nombre y precio
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "\$ ${item.product.basePrice}",
                              ),
                            ],
                          ),

                          /// ➖➕ Cantidad
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    cartController.decreaseQuantity(item),
                                icon: const Icon(Icons.remove),
                              ),
                              Text(item.quantity.toString()),
                              IconButton(
                                onPressed: () =>
                                    cartController.increaseQuantity(item),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// 💰 Total + Pagar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.black12,
                  )
                ],
              ),
              child: Column(
                children: [

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total:",
                        style: TextStyle(fontSize: 18),
                      ),
                      Obx(() => Text(
                            "\$ ${cartController.totalCart.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                    ],
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColorBasic.blue1,
                        foregroundColor: CustomColorBasic.white1
                      ),
                      onPressed: () {
                        Get.snackbar(
                          "Pago",
                          "Procesando pago...",
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: const Text("Pagar", style: TextStyle(fontSize: 15),),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}