import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lacarta/main.dart';
import 'package:lacarta/core/models/order.dart';

class OrderService {
  final FirebaseFirestore _firebaseFirestore = clientDb;
  final String collection = "orders";

    Future<void> saveOrder(OrderCart order ) async{
      _firebaseFirestore.collection(collection).add(order.toMap());
    }
    
}