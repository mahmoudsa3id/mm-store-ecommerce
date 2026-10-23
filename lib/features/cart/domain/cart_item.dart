class CartItem {
  const CartItem({required this.productId, required this.name, required this.image, required this.price, required this.quantity, this.size, this.color});
  final String productId;
  final String name;
  final String image;
  final double price;
  final int quantity;
  final String? size;
  final String? color;

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {'productId': productId, 'name': name, 'image': image, 'price': price, 'quantity': quantity, 'size': size, 'color': color};

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        productId: j['productId'] as String,
        name: j['name'] as String,
        image: j['image'] as String,
        price: (j['price'] as num).toDouble(),
        quantity: j['quantity'] as int,
        size: j['size'] as String?,
        color: j['color'] as String?,
      );

  CartItem copyWith({int? quantity}) => CartItem(productId: productId, name: name, image: image, price: price, quantity: quantity ?? this.quantity, size: size, color: color);
}
