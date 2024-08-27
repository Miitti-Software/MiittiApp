import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseStorageService {
  final Ref ref;
  final FirebaseStorage _firebaseStorage;

  FirebaseStorageService(this.ref) : _firebaseStorage = FirebaseStorage.instance;

  Future<String> uploadUserImage(String uid, File? image) async {
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'picked-file-path': image!.path},
    );

    String filePath = 'userImages/$uid/profilePicture.jpg';
    try {
      final UploadTask uploadTask;
      Reference ref = _firebaseStorage.ref(filePath);

      uploadTask = ref.putData(await image.readAsBytes(), metadata);

      String imageUrl = await (await uploadTask).ref.getDownloadURL();

      return imageUrl;
    } catch (error) {
      throw Exception("Upload failed: $error");
    }
  }

  Future<void> deleteUserFolder(String uid) async {
    String folderPath = 'userImages/$uid';

    try {
      // Delete the folder by listing all items and deleting them
      Reference folderRef = _firebaseStorage.ref(folderPath);
      ListResult result = await folderRef.listAll();

      for (Reference item in result.items) {
        await item.delete();
      }

      for (Reference prefix in result.prefixes) {
        ListResult subResult = await prefix.listAll();
        for (Reference subItem in subResult.items) {
          await subItem.delete();
        }
      }
    } catch (error) {
      throw Exception("Deletion failed: $error");
    }
  }
}