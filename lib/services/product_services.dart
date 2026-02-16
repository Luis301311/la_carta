
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lacarta/models/producto.dart';

class ProductServices {
  final String productCollection = "products";
  final FirebaseFirestore _firebaseStorage = FirebaseFirestore.instance;

  //SAVE
  Future<String> saveProduct(Product product) async{
    DocumentReference dodRef = await _firebaseStorage.collection(productCollection).add(product.toMap());
    return dodRef.id;   
  }

  //Get Products
  Future<List<Product>> getProducts() async {
    QuerySnapshot snapshot =
        await _firebaseStorage.collection(productCollection).get();

    return snapshot.docs
        .map((doc) => Product.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .toList();
  }

  //UPDATE
  Future<void> updateProduct(Product product) async {
    await _firebaseStorage
        .collection(productCollection)
        .doc(product.id)
        .update(product.toMap());
  }
}
