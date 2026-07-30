import 'package:get/get.dart';
import 'package:lacarta/core/models/category.dart';
import 'package:lacarta/core/services/category_services.dart';

class CategoryController extends GetxController {

  final CategoryServices _categoryServices = CategoryServices();
  RxList<ProductCategory> categories = <ProductCategory>[].obs;
  RxList<ProductCategory> filteredCategories = <ProductCategory>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  /// 🔹 Obtener categorías
  void fetchCategories() async {
    isLoading.value = true;
    try {
      categories.value = await _categoryServices.getCategories();
      filteredCategories.value = categories;
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar las categorías');
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Crear categoría
  Future<void> createCategory(ProductCategory category) async {
    isLoading.value = true;
    try {
      await _categoryServices.saveCategory(category);
      
      categories.add(category);
      filteredCategories.value = categories;
      Get.snackbar('Éxito', 'Categoría creada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo crear la categoría');
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Filtrar categorías
  void filterCategory(String query) {
    if (query.isEmpty) {
      filteredCategories.value = categories;
    } else {
      filteredCategories.value = categories.where((category) {
        return category.name
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    }
  }
}
