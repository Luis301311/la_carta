
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lacarta/models/producto.dart';

class ProductServices {
  final String productCollection = "products";
  final FirebaseFirestore _firebaseStorage = FirebaseFirestore.instance;

  //SAVE

  Future<String> saveProduct(Product product) async {
    final doc = await FirebaseFirestore.instance
        .collection(productCollection)
        .add(product.toMap());
    return doc.id;
  }
  
  ///GET
  Future<List<Product>> getProducts() async {
    final snapshot = await _firebaseStorage
        .collection(productCollection)
        .get();

    return snapshot.docs.map((doc) {
      return Product.fromMap(doc.data(), doc.id);
    }).toList();
  }

  //UPDATE
  Future<void> updateProduct(Product product) async {
    await _firebaseStorage
        .collection(productCollection)
        .doc(product.id)
        .update(product.toMap());
  }


}





/* Future<List<Product>> getProductsByCategory(String categoryId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('categories')
      .doc(categoryId)
      .collection('products')
      .get();

  print("Categoria $categoryId → ${snapshot.docs.length} productos");

  return snapshot.docs.map((doc) {
    return Product.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }).toList();
} */

/*   //GET
  Future<List<Product>> getProductss() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collectionGroup('products') // ESCRÍBELO LITERAL
        .get();


    return snapshot.docs.map((doc) {
      return Product.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();

  } */

/*   Future<String> saveProduct(Product product) async {
    final batch = _firebaseStorage.batch();

    final categoryRef = _firebaseStorage.collection('categories').doc(product.categoryId);

    final productRef = categoryRef.collection(productCollection).doc();

    batch.set(productRef, product.toMap());

    for (var extra in product.extras) {
      final extraRef = productRef.collection('extras').doc();
      batch.set(extraRef, extra.toMap());
    }

    // Ejecutar todo junto
    await batch.commit();

    return productRef.id; 
  } */


