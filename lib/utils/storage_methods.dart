import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageMethods {
  static const String _prescriptionBucket = 'prescriptions';
  static const String _communityBucket = 'community';

  /// Uploads an image to Supabase Storage and returns the public URL.
  /// Returns `null` if the upload fails.
  Future<String?> uploadPrescriptionImage(Uint8List fileBytes) async {
    final fileName =
        'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final response = await Supabase.instance.client.storage
          .from(_prescriptionBucket)
          .uploadBinary(fileName, fileBytes);

      if (response.isEmpty) {
        return null;
      }

      final publicUrl = Supabase.instance.client.storage
          .from(_prescriptionBucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading prescription image: $e');
      return null;
    }
  }

  /// Uploads a community post image to Supabase Storage and returns the public URL.
  /// Returns `null` if the upload fails.
  Future<String?> uploadCommunityImage(Uint8List fileBytes) async {
    final fileName =
        'community_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final response = await Supabase.instance.client.storage
          .from(_communityBucket)
          .uploadBinary(fileName, fileBytes);

      if (response.isEmpty) {
        return null;
      }

      final publicUrl = Supabase.instance.client.storage
          .from(_communityBucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading community image: $e');
      return null;
    }
  }
}
