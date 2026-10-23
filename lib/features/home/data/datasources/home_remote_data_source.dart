import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/home_entity.dart';

class HomeRemoteDataSource {
  const HomeRemoteDataSource(this.client);

  final SupabaseClient client;

  Future<HomeContent> getHome() async {
    final response = await client.rpc('get_home_content');
    final map = Map<String, dynamic>.from(response as Map);

    ProductEntity productFromMap(Map<String, dynamic> data) {
      return ProductEntity(
        id: data['id'].toString(),
        name: (data['name'] ?? '').toString(),
        image: (data['image_url'] ?? '').toString(),
        images: List<String>.from((data['images'] as List?) ?? const []),
        price: (data['price'] as num? ?? 0).toDouble(),
        oldPrice: (data['old_price'] as num?)?.toDouble(),
        rating: (data['rating'] as num? ?? 0).toDouble(),
        reviewCount: (data['review_count'] as num? ?? 0).toInt(),
        colors: List<String>.from((data['colors'] as List?) ?? const []),
        sizes: List<String>.from((data['sizes'] as List?) ?? const []),
        description: (data['description'] ?? '').toString(),
        categoryId: data['category_id']?.toString(),
        createdAt: data['created_at'] == null
            ? null
            : DateTime.tryParse(data['created_at'].toString()),
        countSales: (data['sales_count'] as num? ?? 0).toInt(),
      );
    }

    CategoryEntity categoryFromMap(Map<String, dynamic> data) {
      return CategoryEntity(
        id: data['id'].toString(),
        name: (data['name'] ?? '').toString(),
        image: (data['image_url'] ?? '').toString(),
      );
    }

    final hero = _map(map['hero']);
    final about = _map(map['about']);
    final socials = _map(map['socials']);
    final contact = _map(map['contact']);
    final settings = _map(map['settings']);

    return HomeContent(
      hero: HeroContent(
        image: (hero['image'] ?? '').toString(),
        title: (hero['title'] ?? '').toString(),
        subtitle: (hero['subtitle'] ?? '').toString(),
        button: (hero['button'] ?? 'تسوق الآن').toString(),
      ),
      categories: _list(
        map['categories'],
      ).map(categoryFromMap).toList(growable: false),
      services: _list(map['services'])
          .map(
            (item) => ServiceEntity(
              title: (item['title'] ?? '').toString(),
              subtitle: (item['subtitle'] ?? '').toString(),
              icon: (item['icon'] ?? 'verified').toString(),
            ),
          )
          .toList(growable: false),
      bestSellers: _list(
        map['best_sellers'],
      ).map(productFromMap).toList(growable: false),
      newArrivals: _list(
        map['new_arrivals'],
      ).map(productFromMap).toList(growable: false),
      banners: _list(map['banners'])
          .map(
            (item) => BannerEntity(
              image: (item['image_url'] ?? '').toString(),
              title: (item['title'] ?? '').toString(),
              button: (item['button_text'] ?? 'تسوق الآن').toString(),
              target: (item['target'] ?? 'new').toString(),
            ),
          )
          .toList(growable: false),
      about: AboutEntity(
        title: (about['title'] ?? '').toString(),
        description: (about['description'] ?? '').toString(),
        image: (about['image_url'] ?? '').toString(),
      ),
      socials: SocialEntity(
        instagram: (socials['instagram'] ?? '').toString(),
        facebook: (socials['facebook'] ?? '').toString(),
        tiktok: (socials['tiktok'] ?? '').toString(),
        telegram: (socials['youtube'] ?? '').toString(),
      ),
      contact: ContactEntity(
        phone: (contact['phone'] ?? '').toString(),
        email: (contact['email'] ?? '').toString(),
        address: (contact['address'] ?? '').toString(),
      ),
      settings: StoreSettings(
        storeName: (settings['store_name'] ?? 'MM Store').toString(),
        instapayNumber: (settings['instapay_number'] ?? '').toString(),
        cashNumber: (settings['cash_number'] ?? '').toString(),
        phone: (settings['phone'] ?? '').toString(),
        whatsapp: (settings['whatsapp'] ?? '').toString(),
        shippingFee: (settings['shipping_fee'] as num? ?? 0).toDouble(),
        freeShippingThreshold:
            (settings['free_shipping_threshold'] as num? ?? 0).toDouble(),
      ),
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
