import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/controller/product_detail_controller.dart';
import 'package:lacarta/models/producto.dart';
import 'package:lacarta/pages/cart_page.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    final ProductDetailController productoController = Get.put(ProductDetailController(product));
   
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
                    icon: const Icon(Icons.arrow_back, size: 28, color: Colors.blue,)),
                  Row(
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 15),
                      IconButton(
                        onPressed: (){ 
                          Get.to(()=>CartPage());
                          },
                        icon: Icon(Icons.receipt_long,)),
                    ],
                  )
                ],
              ),
            ),

            /// 📦 Contenido
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

                      /// 🖼 Imagen
                      Container(
                        height: 400,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Center(
                          child: Text("Imagen del producto"),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// Indicador
                      const Center(
                        child: Text("1/3"),
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

                      const Text(
                        "Ingredientes o detalles del producto",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// 💲 Precio base
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

                              const SizedBox(height: 10),

                              ...group.options.map((option) {

                                return Obx(() {
                                  final selected = productoController.isSelected(group, option);
                                  return CheckboxListTile(
                                    value: selected,
                                    onChanged: (_) {
                                      productoController.toggleExtra(group, option);
                                    },
                                    title: Text(option.name),
                                    subtitle: option.price > 0
                                        ? Text("+ \$${option.price}")
                                        : null,
                                  );
                                });

                              }).toList(),
                              const SizedBox(height: 20),
                            ],
                          );

                        }).toList(),
                      ),
                      const SizedBox(height: 25),

                      /// 💬 Comentarios
                      const Text(
                        "Comentarios",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Opcional",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// 🔢 Cantidad
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
                          onPressed: () {},
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