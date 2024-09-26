import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseStorageService {
  final Ref ref;
  final FirebaseStorage _firebaseStorage;

  FirebaseStorageService(this.ref) : _firebaseStorage = FirebaseStorage.instance;

  Future<String> uploadProfilePicture(String uid, File? image) async {
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'picked-file-path': image!.path},
    );

    String filePath = 'userImages/$uid/profilePicture.jpg';
    String thumbnailPath = 'userImages/$uid/thumb_profilePicture.jpg';
    
    try {
      // Process and upload the main image
      File mainImage = await _compressAndResizeImage(image, 1024, 50);
      Reference ref = _firebaseStorage.ref(filePath);
      await ref.putFile(mainImage, metadata);
      String imageUrl = await ref.getDownloadURL();

      // Process and upload the thumbnail
      File thumbnail = await _compressAndResizeImage(image, 150, 50);
      Reference thumbRef = _firebaseStorage.ref(thumbnailPath);
      await thumbRef.putFile(thumbnail, metadata);

      return imageUrl;
    } catch (error) {
      throw Exception("Upload failed: $error");
    }
  }

  Future<File> _compressAndResizeImage(File? image, int maxDimension, int quality) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;
    final targetPath = '$tempPath${DateTime.now().millisecondsSinceEpoch}.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      image!.absolute.path,
      targetPath,
      minWidth: maxDimension,
      minHeight: maxDimension,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    return File(result!.path);
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