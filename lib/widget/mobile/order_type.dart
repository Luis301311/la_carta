import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/constant/order_status.dart';
import 'package:lacarta/controller/cart_controller.dart';
import 'package:lacarta/controller/order_controller.dart';
import 'package:lacarta/models/order.dart';
import 'package:lacarta/widget/mobile/form/delivery_form.dart';
import 'package:lacarta/widget/mobile/form/takeawuay_form.dart';

class OrderTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onSelected;

  OrderTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });
  final CartController cartController = Get.find<CartController>();
  final OrderController orderController = Get.put(OrderController());

  Widget _buildOption(
    BuildContext context,
    String type,
    String title,
    IconData icon,
  ) {
    final bool selected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        
        onTap: (){
          onSelected(type);
          if (type == OrderType.delivery) {
            Get.bottomSheet(
              DeliveryForm(),
              isScrollControlled: true,
            );
          }
          if(type == OrderType.takeaway){
            Get.bottomSheet(
              TakeawayForm(),
              isScrollControlled: true,
            );
          }
        }, 
        child: Container(
          height: 130,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected ? CustomColorBasic.yellow : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: selected ? Colors.white : Colors.black,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildOption(context, OrderType.dineIn, "Consumir aquí", Icons.restaurant),
        _buildOption(context, OrderType.takeaway, "Para llevar", Icons.shopping_bag),
        _buildOption(context, OrderType.delivery, "Domicilio", Icons.delivery_dining),
      ],
    );
  }
}