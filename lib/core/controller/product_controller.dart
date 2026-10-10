import 'package:get/get.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/controller/company_controller.dart';
import 'package:lacarta/core/models/product/producto.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/product_services.dart';

class ProductController extends GetxController {
  /// false = menú público (cliente). true = panel (todos los productos, vía API con sesión).
  /// En el panel se registra con tag: Get.put(ProductController(admin: true), tag: 'admin')
  final bool admin;
  ProductController({this.admin = false});

  final ProductServices _productServices = ProductServices();
  RxList<Product> products = <Product>[].obs;
  RxList<Product> filteredProducts = <Product>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  /// - Cliente (sin sesión): usa el menú público ya cargado.
  /// - Admin (con sesión): pide a la API todos los productos, incluidos los no disponibles.
  Future<void> fetchProducts() async {
    isLoading.value = true;
    try {
      final companyId = AuthController.to.activeCompanyId.value;
      if (admin) {
        if (companyId == null) return;
        products.assignAll(await _productServices.getProducts(companyId));
      } else {
        products.assignAll(Get.find<RestaurantController>().products);
      }
      filteredProducts.assignAll(products);
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Panel: crea el producto (con sus extras) en la API
  Future<bool> createProduct(Product product) async {
    final companyId = AuthController.to.activeCompanyId.value;
    if (companyId == null) {
      Get.snackbar('Error', 'No hay restaurante seleccionado');
      return false;
    }
    isLoading.value = true;
    try {
      final created = await _productServices.createProduct(companyId, product);
      products.add(created);
      filteredProducts.assignAll(products);
      Get.snackbar('Éxito', 'Producto creado correctamente');
      return true;
    } on ApiException catch (e) {
      Get.snackbar('No se pudo crear el producto', e.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Panel: guarda los cambios (incluidos los grupos de extras)
  Future<bool> updateProduct(Product product) async {
    final companyId = AuthController.to.activeCompanyId.value;
    if (companyId == null || product.id == null) return false;
    isLoading.value = true;
    try {
      final updated = await _productServices.updateProduct(companyId, product);
      _replace(updated);
      Get.snackbar('Guardado', '"${updated.name}" actualizado');
      return true;
    } on ApiException catch (e) {
      Get.snackbar('No se pudo guardar', e.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Panel: marcar agotado / disponible en un toque (sin tocar lo demás)
  Future<void> setAvailability(Product product, bool isAvailable) async {
    final companyId = AuthController.to.activeCompanyId.value;
    if (companyId == null || product.id == null) return;
    // Se cambia en pantalla de una vez y se revierte si la API falla
    _replace(product.copyWith(isAvailable: isAvailable));
    try {
      await _productServices.setAvailability(
          companyId, product.id!, isAvailable);
    } on ApiException catch (e) {
      _replace(product);
      Get.snackbar('No se pudo cambiar', e.message);
    }
  }

  Future<bool> deleteProduct(Product product) async {
    final companyId = AuthController.to.activeCompanyId.value;
    if (companyId == null || product.id == null) return false;
    try {
      await _productServices.deleteProduct(companyId, product.id!);
      products.removeWhere((p) => p.id == product.id);
      filteredProducts.assignAll(products);
      Get.snackbar('Eliminado', '"${product.name}" se eliminó');
      return true;
    } on ApiException catch (e) {
      Get.snackbar('No se pudo eliminar', e.message);
      return false;
    }
  }

  void _replace(Product product) {
    final i = products.indexWhere((p) => p.id == product.id);
    if (i != -1) products[i] = product;
    filteredProducts.assignAll(products);
  }

  void filteredProductForCategory(String categoryId) {
    if (categoryId.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      filteredProducts.assignAll(
          products.where((p) => p.categoryId == categoryId));
    }
  }

  void filteredProduct(String query) {
    if (query.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      final q = query.toLowerCase();
      filteredProducts.assignAll(products.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q)));
    }
  }
}
