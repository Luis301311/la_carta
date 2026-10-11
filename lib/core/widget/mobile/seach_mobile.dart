import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/custom_colors.dart';

/// Barra de búsqueda fija del menú.
/// Va dentro de un encabezado de 60 px: el campo es "denso" para que quepa
/// (antes medía ~76 px con el padding y se desbordaba).
class SeachMobile extends StatelessWidget {
  /// Se llama con cada letra que escribe el cliente
  final ValueChanged<String> onChanged;
  const SeachMobile({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomColorBasic.white2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                hintText: "Buscar en el menú...",
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
