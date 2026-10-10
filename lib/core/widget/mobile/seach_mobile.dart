import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/custom_colors.dart';

/// Barra de búsqueda fija del menú.
/// Va dentro de un encabezado de 60 px: el campo es "denso" para que quepa
/// (antes medía ~76 px con el padding y se desbordaba).
class SeachMobile extends StatelessWidget {
  const SeachMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomColorBasic.white2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                hintText: "Buscar...",
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {},
            icon: const Icon(Icons.tune, size: 28),
          )
        ],
      ),
    );
  }
}
