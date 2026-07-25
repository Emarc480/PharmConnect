/// A single promotional banner image shown in the Home screen's
/// "Special Offers" carousel. Up to `PromoBannerProvider.maxSlots`
/// (5) can exist, one per `order` position (0-4).
///
/// Images are stored inline as base64, the same way `Drug.imageBase64`
/// stores drug photos — small enough to stay under Firestore's 1MB
/// document cap while avoiding a Cloud Storage dependency.
library;

class PromoBanner {
  final String id;
  final int order;
  final String imageBase64;

  const PromoBanner({
    required this.id,
    required this.order,
    required this.imageBase64,
  });

  factory PromoBanner.fromMap(String id, Map<String, dynamic> map) {
    return PromoBanner(
      id: id,
      order: ((map['order'] as num?) ?? 0).toInt(),
      imageBase64: (map['imageBase64'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order': order,
      'imageBase64': imageBase64,
    };
  }
}