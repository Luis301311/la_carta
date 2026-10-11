import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/menu_brand.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/widget/mobile/form/order_form.dart';

class OrderTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onSelected;

  const OrderTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  Widget _buildOption(
    BuildContext context,
    String type,
    String title,
    IconData icon,
  ) {
    final bool selected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onSelected(type);
          Get.bottomSheet(
            OrderForm(type: type),
            isScrollControlled: true,
          );
        },
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected ? MenuBrand.color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: selected ? MenuBrand.onColor : Colors.black,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                    color: selected ? MenuBrand.onColor : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
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
        _buildOption(
            context, OrderType.dineIn, "Consumir aqui", Icons.restaurant),
        _buildOption(
            context, OrderType.takeaway, "Para llevar", Icons.shopping_bag),
        _buildOption(
            context, OrderType.delivery, "Domicilio", Icons.delivery_dining),
      ],
    );
  }
}
