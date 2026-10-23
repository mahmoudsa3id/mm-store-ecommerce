import 'package:mm_store/features/home/domain/entities/product_color_variant.dart';

class HomeContent {
  const HomeContent({
    required this.hero,
    required this.categories,
    required this.services,
    required this.bestSellers,
    required this.newArrivals,
    required this.banners,
    required this.about,
    required this.socials,
    required this.contact,
    required this.settings,
  });

  final HeroContent hero;
  final List<CategoryEntity> categories;
  final List<ServiceEntity> services;
  final List<ProductEntity> bestSellers;
  final List<ProductEntity> newArrivals;
  final List<BannerEntity> banners;
  final AboutEntity about;
  final SocialEntity socials;
  final ContactEntity contact;
  final StoreSettings settings;
}

class HeroContent {
  const HeroContent({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.button,
  });
  final String image;
  final String title;
  final String subtitle;
  final String button;
}

class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.image,
  });
  final String id;
  final String name;
  final String image;
}

class ServiceEntity {
  const ServiceEntity({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final String icon;
}

class ProductEntity {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.oldPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.colors = const [],
    this.colorVariants = const [],
    this.sizes = const [],
    this.images = const [],
    this.description = '',
    this.categoryId,
    this.createdAt,
    this.isActive = true,
    required this.countSales,
  });

  final String id;
  final String name;
  final String image;
  final double price;
  final double? oldPrice;
  final double rating;
  final int reviewCount;

  /// الألوان القديمة - نحتفظ بها للتوافق مع الكود الحالي.
  final List<String> colors;

  /// كل لون مرتبط بصورة خاصة به.
  final List<ProductColorVariant> colorVariants;

  final List<String> sizes;
  final List<String> images;
  final String description;
  final String? categoryId;
  final DateTime? createdAt;
  final bool isActive;
  final int countSales;

  int? get discountPercent {
    if (oldPrice == null || oldPrice! <= price) return null;

    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }
}

class BannerEntity {
  const BannerEntity({
    required this.image,
    required this.title,
    required this.button,
    required this.target,
  });
  final String image;
  final String title;
  final String button;
  final String target;
}

class AboutEntity {
  const AboutEntity({
    required this.title,
    required this.description,
    required this.image,
  });
  final String title;
  final String description;
  final String image;
}

class SocialEntity {
  const SocialEntity({
    required this.instagram,
    required this.facebook,
    required this.tiktok,
    required this.telegram,
  });
  final String instagram;
  final String facebook;
  final String tiktok;
  final String telegram;
}

class ContactEntity {
  const ContactEntity({
    required this.phone,
    required this.email,
    required this.address,
  });
  final String phone;
  final String email;
  final String address;
}

class StoreSettings {
  const StoreSettings({
    required this.storeName,
    required this.instapayNumber,
    required this.cashNumber,
    required this.phone,
    required this.whatsapp,
    required this.shippingFee,
    required this.freeShippingThreshold,
  });

  final String storeName;
  final String instapayNumber;
  final String cashNumber;
  final String phone;
  final String whatsapp;
  final double shippingFee;
  final double freeShippingThreshold;

  static const empty = StoreSettings(
    storeName: 'MM Store',
    instapayNumber: '',
    cashNumber: '',
    phone: '',
    whatsapp: '',
    shippingFee: 60,
    freeShippingThreshold: 1500,
  );
}
