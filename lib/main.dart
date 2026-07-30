import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lacarta/features/menu/pages/index_pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lacarta/core/controller/cart_controller.dart';
late FirebaseApp clientApp;
late FirebaseFirestore clientDb;
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Firebase de la plataforma
  await Firebase.initializeApp(
    name:"lacarta-platform",
    options: const FirebaseOptions(
      apiKey: "AIzaSyAh1tQw9WDKaQ3fPQNxhyjUuaYh1sV6vIQ",
      appId: "1:913730650705:web:36d7374ca2af469e762e70",
      messagingSenderId: "913730650705",
      projectId: "lacarta-platform",
    ),
  );

  FirebaseFirestore platformDb =
      FirebaseFirestore.instanceFor(app: Firebase.app("lacarta-platform"));

  // Obtener slug desde URL
  final slug = Uri.base.pathSegments.isNotEmpty
      ? Uri.base.pathSegments.first
      : "burger_house";

  // Buscar cliente
  final doc = await platformDb.collection("clients").doc(slug).get();

  final data = doc.data();

  if (data == null) {
    throw Exception("Cliente no encontrado");
  }

  // Inicializar Firebase del cliente
  clientApp = await Firebase.initializeApp(
    name: "LaCarta-1",
    options: FirebaseOptions(
      apiKey: data["apiKey"],
      appId: data["appId"],
      messagingSenderId: data["messagingSenderId"],
      projectId: data["projectId"],
    ),
  );

  clientDb = FirebaseFirestore.instanceFor(app: clientApp);
  Get.put(CartController());
  runApp(MyApp());
}





class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "La Carta",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: Colors.blue
      ),
      home: IndexPages(),
    );
  }
}

