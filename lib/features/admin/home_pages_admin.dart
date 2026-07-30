import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/controller/product_controller.dart';
import 'package:lacarta/features/admin/create_product_page.dart';

class HomePagesAdmin extends StatelessWidget {
  HomePagesAdmin({super.key});

  final ProductController productController =Get.put(ProductController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        title: const Text("Panel Administrador"),
        centerTitle: false,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Row(
              children: [

                Expanded(
                  child: _cardInfo(
                    Icons.shopping_cart,
                    "Pedidos",
                    "15",
                    Colors.orange,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: _cardInfo(
                    Icons.fastfood,
                    "Productos",
                    "40",
                    Colors.green,
                  ),
                ),

              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [

                Expanded(
                  child: _cardInfo(
                    Icons.attach_money,
                    "Ventas",
                    "\$540.000",
                    Colors.blue,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: _cardInfo(
                    Icons.people,
                    "Clientes",
                    "120",
                    Colors.purple,
                  ),
                ),

              ],
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Acciones rápidas",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.5,
              children: [

                _button(
                  Icons.add_box,
                  "Agregar Producto",
                  () {
                    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const CreateProductPage(),
  ),
);
                  },
                ),

                _button(
                  Icons.category,
                  "Categorías",
                  () {
                    Get.toNamed("/admin/categories");
                  },
                ),

                _button(
                  Icons.receipt_long,
                  "Pedidos",
                  () {
                    Get.toNamed("/admin/orders");
                  },
                ),

                _button(
                  Icons.bar_chart,
                  "Reportes",
                  () {
                    Get.toNamed("/admin/reports");
                  },
                ),

              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _cardInfo(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [

            Icon(
              icon,
              color: color,
              size: 35,
            ),

            const SizedBox(height: 10),

            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(title),

          ],
        ),
      ),
    );
  }

  Widget _button(
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              icon,
              size: 35,
            ),

            const SizedBox(height: 10),

            Text(title),

          ],
        ),
      ),
    );
  }
}