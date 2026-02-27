import 'package:get/get.dart';
import 'package:lacarta/models/producto.dart';
import 'package:lacarta/services/product_services.dart';

class ProductController extends GetxController{
  final ProductServices _productServices = ProductServices();
  RxList<Product> products= <Product>[].obs;
  RxList<Product> filteredProducts = <Product>[].obs;
  RxBool isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  void fetchProducts() async {
    isLoading.value = true;
    try {
      products.value = await _productServices.getProducts();
      products.sort((a, b) => a.name.compareTo(b.name));
      filteredProducts.value = products;
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los productos');
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> createProduct(Product product) async {
    isLoading.value = true;
    try {
      final id = await _productServices.saveProduct(product);
      product.id = id; 
      products.add(product);
      filteredProducts.value = products;
      Get.snackbar('Éxito', 'Producto creado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo crear el producto');
    } finally {
      isLoading.value = false;
    }
  }

  void filteredProductForCategory(String query) {
    if (query.isEmpty) {
      filteredProducts.value = products;
    } else {
      filteredProducts.value = products.where((box) {
        return  (box.categoryId.toString()).toLowerCase() == query.toLowerCase();
      }).toList();
    }
  }

  void filteredProduct(String query) {
    if (query.isEmpty) {
      filteredProducts.value = products;
    } else {
      filteredProducts.value = products.where((box) {
        return box.name.toLowerCase().contains(query.toLowerCase()) ||
            (box.categoryId.toString()).contains(query.toLowerCase());
      }).toList();
    }
  }


  
}