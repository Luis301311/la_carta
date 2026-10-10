import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/order_controller.dart';
import 'package:lacarta/core/controller/product_detail_controller.dart';
import 'package:lacarta/core/models/product/producto.dart';
import 'package:lacarta/features/menu/pages/cart_page.dart';
import 'package:lacarta/core/widget/mobile/form/order_type.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    // Un controlador por producto (tag): antes se reutilizaba el del primer
    // producto abierto y se mezclaban extras entre productos.
    final ProductDetailController productoController = Get.put(
      ProductDetailController(product),
      tag: product.id ?? product.name,
    );
    final OrderController orderController = Get.find<OrderController>();
    return Scaffold(
      backgroundColor: CustomColorBasic.white1,
      body: SafeArea(
        child: Column(
          children: [

            /// Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.arrow_back, size: 28, color: Colors.blue,)
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: (){ 
                          Get.to(()=>CartPage());
                          },
                        icon: Icon(Icons.receipt_long,)
                      ),
                      Text("Pedido", style: TextStyle( fontSize: 12),)
                    ],
                  )
                ],
              ),
            ),

            ///  Contenido
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                       Column(
                        children: [

                          /// IMAGENES
                          SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: product.imageUrl.isEmpty
                              ? Container(
                                  color: CustomColorBasic.white3,
                                  child: const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                                )
                              : PageView.builder(
                              itemCount: product.imageUrl.length,
                              onPageChanged: (index) {
                                productoController.currentPage.value = index;
                              },
                              itemBuilder: (context, index) {
                                return Image.network(
                                  product.imageUrl[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image, size: 60, color: Colors.grey),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// INDICADOR
                        Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          product.imageUrl.length,
                          (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: productoController.currentPage.value == index ? 12 : 8,
                              height: productoController.currentPage.value == index ? 12 : 8,
                              decoration: BoxDecoration(
                                color: productoController.currentPage.value == index
                                    ? Colors.black
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        ),
                      )),
                        ],
                      ),
                      const SizedBox(height: 20),

                      /// 🏷 Nombre
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                       Text(
                        productoController.product.description,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Precio base
                      Text(
                        "\$ ${product.basePrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        children: product.extras.map((group) {

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                group.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              if (group.isRequired)
                                const Text(
                                  "Obligatorio",
                                  style: TextStyle(color: Colors.red),
                                ),
                                ...group.options.map((option) {
                                  return Obx(() {
                                    final qty =
                                        productoController.getQuantity(group, option);

                                    return ListTile(
                                      title: Text(option.name),
                                      subtitle: option.price > 0
                                          ? Text("+ \$${option.price.toStringAsFixed(0)}")
                                          : null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [

                                          // Botón -
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: qty > 0
                                                ? () => productoController
                                                    .decrementExtra(group, option)
                                                : null,
                                          ),

                                          // Cantidad
                                          Text(
                                            qty.toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          // Botón +
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () =>
                                                productoController
                                                    .incrementExtra(group, option),
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                }),
                              const SizedBox(height: 20),
                            ],
                          );

                        }).toList(),
                      ),
                      const SizedBox(height: 25),

                      ///  Comentarios
                      const Text(
                        "Comentarios",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        onChanged: (value) {
                          productoController.comment.value = value; 
                        },
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Opcional",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      ///  Cantidad
                      const Text(
                        "Cantidad",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// Botones -
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    productoController.decrease();
                                  },
                                  icon: const Icon(Icons.remove),
                                ),
                                Obx(()=>
                                  Text(
                                    productoController.quantity.toString(),
                                    style: const TextStyle(fontSize: 18),
                                  )),
                                IconButton(
                                  onPressed: () {
                                  productoController.increase();
                                  },
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),

                          /// 💰 Total
                          Obx(()=>
                            Text(
                              "\$ ${productoController.total.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 18,
                                color: CustomColorBasic.green1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      /// 🛒 Agregar al pedido
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            productoController.addToCart();
                          },
                          child: const Text(
                            "Agregar al Pedido",
                            style: TextStyle(fontSize: 16, color: CustomColorBasic.black1),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ⚡ Comprar ahora
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomColorBasic.blue1,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                             productoController.buyNow(product);
                              Get.bottomSheet(
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                child: Obx(() => OrderTypeSelector(
                                      selectedType: orderController.orderType.value,
                                      onSelected: (type) {
                                        orderController.orderType.value = type;
                                      },
                                )),
                              )
                            );
                          },
                          child: const Text(
                            "Comprar ahora",
                            style: TextStyle(fontSize: 16, color: CustomColorBasic.white1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}