import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/constant/list_producto.dart';
class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColorBasic.white2,
      body: Center(
        child: 
        //IconButton(onPressed: (){addProductss();}, icon: Icon(Icons.nat_outlined))
        Text("En desarrollo...")
        ),
    );
  }
}