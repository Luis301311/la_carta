import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lacarta/main.dart';
import 'package:lacarta/core/models/company/company.dart';

class CompanyService {
  final FirebaseFirestore _firestore = clientDb;
  final String collection = 'company';
  
  Future<List<Company>> getCompanies() async {
    try {
      final snapshot = await _firestore.collection(collection).get();

      return snapshot.docs.map((doc) {
        return Company.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception("Error fetching companies: $e");
    }
  }

  Future<Company?> getCompanyById(String id) async {
    try {
      final doc = await _firestore.collection(collection).doc(id).get();

      if (!doc.exists) return null;

      return Company.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception("Error fetching company: $e");
    }
  }

  /// 🔹 CREATE
  Future<void> createCompany(Company company) async {
    try {
      await _firestore
          .collection(collection)
          .doc(company.id)
          .set(company.toMap());
    } catch (e) {
      throw Exception("Error creating company: $e");
    }
  }

  /// 🔹 UPDATE
  Future<void> updateCompany(Company company) async {
    try {
      await _firestore
          .collection(collection)
          .doc(company.id)
          .set(
            company.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception("Error updating company: $e");
    }
  }


}

