import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lacarta/models/order.dart';

class OrderService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final String collection = "orders";

    Future<void> saveOrder(OrderCart order ) async{
      _firebaseFirestore.collection(collection).add(order.toMap());
    }
    
}