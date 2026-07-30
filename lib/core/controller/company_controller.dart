import 'package:get/get.dart';
import 'package:lacarta/core/models/company/business_hours.dart';
import 'package:lacarta/core/models/company/company.dart';
import 'package:lacarta/core/services/company_service.dart';

class CompanyController extends GetxController {
  final CompanyService companyService = CompanyService();
  Rxn<Company> company = Rxn<Company>(); 
  RxBool isLoading = false.obs; 
  RxBool isOpen = false.obs;
  @override
  void onInit() {
    super.onInit();
    fetchCompany();

    //Status
    ever(company, (_) => checkIfOpen());

    Future.doWhile(() async {
      await Future.delayed(Duration(minutes: 1));
      checkIfOpen();
      return true;
    });
  }

  // GET COMPANY (solo una)
  void fetchCompany() async {
    isLoading.value = true;

    try {
      final companies = await companyService.getCompanies();

      if (companies.isNotEmpty) {
        company.value = companies.first; 
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not load company data');
    } finally {
      isLoading.value = false;
    }
  }

  // UPDATE COMPANY
  Future<void> updateCompany(Company updatedCompany) async {
    try {
      isLoading.value = true;

      await companyService.updateCompany(updatedCompany);

      company.value = updatedCompany;

      Get.snackbar('Success', 'Company updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Error updating company');
    } finally {
      isLoading.value = false;
    }
  }

  // CREATE (solo para pruebas)
  Future<void> createCompany(Company newCompany) async {
    try {
      isLoading.value = true;

      await companyService.createCompany(newCompany);

      company.value = newCompany;

      Get.snackbar('Success', 'Company created');
    } catch (e) {
      Get.snackbar('Error', 'Error creating company');
    } finally {
      isLoading.value = false;
    }
  }



  void checkIfOpen() {
    if (company.value != null) {
      isOpen.value = isCompanyOpen(company.value!);
    }
  }


  bool isCompanyOpen(Company company) {
    final now = DateTime.now();

    // Día actual en inglés (igual que tu modelo)
    final currentDay = _getDayName(now.weekday);

    // Buscar horario de hoy
    final todaySchedule = company.businessHours.firstWhere(
      (h) => h.day == currentDay,
      orElse: () => BusinessHours(
        day: currentDay,
        openTime: "",
        closeTime: "",
        closed: true,
      ),
    );

    // Si está cerrado
    if (todaySchedule.closed) return false;

    // Convertir horas a DateTime
    final openParts = todaySchedule.openTime.split(":");
    final closeParts = todaySchedule.closeTime.split(":");

    final openTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(openParts[0]),
      int.parse(openParts[1]),
    );

    final closeTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(closeParts[0]),
      int.parse(closeParts[1]),
    );

    return now.isAfter(openTime) && now.isBefore(closeTime);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      case 7:
        return "Sunday";
      default:
        return "";
    }
  }

}