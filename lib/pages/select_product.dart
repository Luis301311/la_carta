import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/models/producto.dart';

 class SelectProduct extends StatelessWidget {
  final Product product ; 
  const SelectProduct({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColorBasic.white1,
      body: Container(
        child: Text("Luis"),
      ),
    );
  }
}