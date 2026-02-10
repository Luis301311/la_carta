import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/pages/home_pages.dart';

class IndexPages extends StatefulWidget {
  const IndexPages({super.key});

  @override
  State<IndexPages> createState() => _IndexPagesState();
}

class _IndexPagesState extends State<IndexPages> {
  @override
  Widget build(BuildContext context) {
    int selectedIndex = 0; 
    final List<Widget> pages =<Widget>[HomePages(), HomePages()];  // VISTAS

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        items: [
          _buildNavItem(Icons.restaurant, "Menu", 0, selectedIndex),
          _buildNavItem(Icons.receipt_long, "Pedido", 1, selectedIndex),
          _buildNavItem(Icons.place, "Ubicacion", 2, selectedIndex)
        ],
        onTap: (value) {
           setState(() {
            selectedIndex = value;
          });
        },
        backgroundColor: CustomColorBasic.white2, // Fondo detrás de la barra de navegación
        buttonBackgroundColor: CustomColorBasic.yellow2, // Fondo del botón activo
        color: CustomColorBasic.white1, // Color de la barra de navegación
        animationDuration: const Duration(milliseconds: 300), // Ajuste del tiempo de animación
        animationCurve: Curves.easeInOut, // Añadir curva de animación suave
        height: 70, // Ajustar la altura del navbar para dar más espacio

      ),
    );
  }
}


Widget _buildNavItem(IconData icon, String label, int index, int selectedIndex ) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 30, color: selectedIndex == index ? Colors.black : Colors.black),
      if (selectedIndex != index)
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
    ],
  );
}

