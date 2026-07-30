import 'dart:typed_data';
import 'package:lacarta/main.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final storage = FirebaseStorage.instanceFor(app: clientApp);

  Future<String> uploadProductImage(Uint8List bytes) async {
    try {
      
      final ref = storage.ref(
        'products/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      print("Estado: ${task.state}");

      final url = await ref.getDownloadURL();
      print("URL: $url");

      return url;
    } catch (e, s) {
      print("ERROR STORAGE:");
      print(e);
      print(s);
      rethrow;
    }
  }
}