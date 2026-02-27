import 'package:flutter/material.dart';
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
      body: IconButton(onPressed: (){addProducts();}, icon: Icon(Icons.construction)),
    );
  }
}