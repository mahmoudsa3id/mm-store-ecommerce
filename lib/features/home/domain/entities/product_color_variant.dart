class ProductColorVariant {
  const ProductColorVariant({required this.color, required this.imageUrl});

  final String color;
  final String imageUrl;

  factory ProductColorVariant.fromJson(Map<String, dynamic> json) {
    return ProductColorVariant(
      color: json['color']?.toString() ?? '#000000',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'color': color, 'image_url': imageUrl};
  }
}
