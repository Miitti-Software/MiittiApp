import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A service class to manage Firebase Storage operations
class FirebaseStorageService {
  final Ref ref;
  final FirebaseStorage _firebaseStorage;

  FirebaseStorageService(this.ref) : _firebaseStorage = FirebaseStorage.instance;

  /// Uploads a profile picture to Firebase Storage and returns the download URL.
  /// The image is stored in a folder corresponding to the user ID under 'userImages' with the name 'profilePicture.jpg'.
  Future<String> uploadProfilePicture(String uid, File? image) async {
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

  /// Deletes all of the user's images associated with the given user ID.
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