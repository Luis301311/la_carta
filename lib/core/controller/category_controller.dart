import 'package:get/get.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/controller/company_controller.dart';
import 'package:lacarta/core/models/category.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/category_services.dart';

class CategoryController extends GetxController {
  /// false = menú público. true = panel (en el panel: tag 'admin')
  final bool admin;
  CategoryController({this.admin = false});

  final CategoryServices _categoryServices = CategoryServices();
  RxList<ProductCategory> categories = <ProductCategory>[].obs;
  RxList<ProductCategory> filteredCategories = <ProductCategory>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  /// Cliente: categorías del menú público. Admin: todas desde la API.
  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      final companyId = AuthController.to.activeCompanyId.value;
      if (admin) {
        if (companyId == null) return;
        categories
            .assignAll(await _categoryServices.getCategories(companyId));
      } else {
        categories.assignAll(Get.find<RestaurantController>().categories);
      }
      filteredCategories.assignAll(categories);
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Panel: crear categoría
  Future<bool> createCategory(ProductCategory category) async {
    final companyId = AuthController.to.activeCompanyId.value;
    if (companyId == null) return false;
    isLoading.value = true;
    try {
      final created =
          await _categoryServices.createCategory(companyId, category);
      categories.add(created);
      filteredCategories.assignAll(categories);
      Get.snackbar('Éxito', 'Categoría creada correctamente');
      return true;
    } on ApiException catch (e) {
      Get.snackbar('No se pudo crear la categoría', e.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void filterCategory(String query) {
    if (query.isEmpty) {
      filteredCategories.assignAll(categories);
    } else {
      final q = query.toLowerCase();
      filteredCategories
          .assignAll(categories.where((c) => c.name.toLowerCase().contains(q)));
    }
  }
}
