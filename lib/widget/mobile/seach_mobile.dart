import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/constant/list_producto.dart';

class SeachMobile extends StatelessWidget {
  const SeachMobile({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Container(
      color: CustomColorBasic.white2,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  
                ),
                hintText: "Buscar...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(width: 20,),
          IconButton(
            onPressed: (){}, 
            icon: Icon(Icons.tune, size: 30,)
          )
        ],
      ),
    );
  }
}