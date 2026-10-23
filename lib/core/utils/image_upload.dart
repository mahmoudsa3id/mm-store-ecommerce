import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PickedImageData {
  const PickedImageData({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

class ImageCompressionProfile {
  const ImageCompressionProfile({
    required this.maxWidth,
    required this.quality,
  });

  final int maxWidth;
  final int quality;

  static const product = ImageCompressionProfile(maxWidth: 1200, quality: 82);
  static const store = ImageCompressionProfile(maxWidth: 1600, quality: 82);
  static const proof = ImageCompressionProfile(maxWidth: 1600, quality: 78);
}

class ImageCompressionService {
  const ImageCompressionService();

  Future<PickedImageData> compress(
    PickedImageData input,
    ImageCompressionProfile profile,
  ) {
    return Isolate.run(() {
      final decoded = img.decodeImage(input.bytes);
      if (decoded == null) {
        throw const FormatException('تعذر قراءة الصورة');
      }

      var working = img.bakeOrientation(decoded);
      if (working.width > profile.maxWidth) {
        working = img.copyResize(
          working,
          width: profile.maxWidth,
          interpolation: img.Interpolation.cubic,
        );
      }

      final bytes = img.encodeWebP(
        working,
        lossless: false,
        quality: profile.quality,
        method: 6,
      );

      return PickedImageData(
        bytes: Uint8List.fromList(bytes),
        extension: 'webp',
      );
    });
  }
}

class ImageUploadService {
  ImageUploadService(
    this.client, [
    this.compressor = const ImageCompressionService(),
  ]);

  final SupabaseClient client;
  final ImageCompressionService compressor;
  final _uuid = const Uuid();

  final ImagePicker _picker = ImagePicker();

  Future<PickedImageData?> pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (file == null) {
        return null;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        return null;
      }

      final name = file.name.toLowerCase();

      String extension;

      if (name.endsWith('.png')) {
        extension = 'png';
      } else if (name.endsWith('.webp')) {
        extension = 'webp';
      } else {
        extension = 'jpg';
      }

      return PickedImageData(bytes: bytes, extension: extension);
    } catch (error) {
      throw Exception('تعذر اختيار الصورة: $error');
    }
  }

  String _contentType(String ext) => switch (ext) {
    'webp' => 'image/webp',
    'png' => 'image/png',
    _ => 'image/jpeg',
  };

  Future<PickedImageData> _optimized(
    PickedImageData image,
    ImageCompressionProfile profile,
  ) async {
    try {
      return await compressor.compress(image, profile);
    } on Object {
      // Preserve the original selection when an image decoder cannot handle it.
      return image;
    }
  }

  Future<String> uploadProductImage(PickedImageData image) async {
    final optimized = await _optimized(image, ImageCompressionProfile.product);
    const bucket = 'product-images';
    final path = '${_uuid.v4()}.${optimized.extension}';

    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          optimized.bytes,
          fileOptions: FileOptions(
            contentType: _contentType(optimized.extension),
            cacheControl: '31536000',
            upsert: false,
          ),
        );

    return client.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> uploadStoreImage(PickedImageData image) async {
    final optimized = await _optimized(image, ImageCompressionProfile.store);
    const bucket = 'store-media';
    final path = 'content/${_uuid.v4()}.${optimized.extension}';

    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          optimized.bytes,
          fileOptions: FileOptions(
            contentType: _contentType(optimized.extension),
            cacheControl: '31536000',
            upsert: false,
          ),
        );

    return client.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> uploadPaymentProof({
    required String orderId,
    required String accessToken,
    required PickedImageData image,
  }) async {
    final optimized = await _optimized(image, ImageCompressionProfile.proof);
    const bucket = 'payment-proofs';
    final path =
        'orders/$orderId/$accessToken/${_uuid.v4()}.${optimized.extension}';

    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          optimized.bytes,
          fileOptions: FileOptions(
            contentType: _contentType(optimized.extension),
            cacheControl: '86400',
            upsert: false,
          ),
        );

    return path;
  }

  Future<String> createPaymentProofSignedUrl(String path) =>
      client.storage.from('payment-proofs').createSignedUrl(path, 600);
}
