import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lacarta/models/category.dart';

class CategoryServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collection = 'categories';


  /// SAVE
  Future<String> saveCategory(ProductCategory category) async {
    await _firestore
        .collection(collection)
        .doc(category.id)
        .set(category.toMap());

    return category.id;
  }
  
  ///GET
  Future<List<ProductCategory>> getCategories() async {
    final snapshot = await _firestore
        .collection(collection)
        .orderBy('order')
        .get();

    return snapshot.docs.map((doc) {
      return ProductCategory.fromMap(doc.data(), doc.id);
    }).toList();
  }
}
