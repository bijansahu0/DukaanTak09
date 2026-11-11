import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id, shopId, emoji, name, weight, category;
  final int price, mrp, stock;
  const Product({
    required this.id,
    required this.shopId,
    required this.emoji,
    required this.name,
    required this.weight,
    required this.category,
    required this.price,
    required this.mrp,
    required this.stock,
  });
  int get off => mrp > price ? ((mrp - price) / mrp * 100).round() : 0;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Product(
      id: d.id,
      shopId: m['shopId'] ?? '',
      emoji: m['emoji'] ?? '🛍️',
      name: m['name'] ?? '',
      weight: m['weight'] ?? '',
      category: m['category'] ?? '',
      price: (m['price'] ?? 0).toInt(),
      mrp: (m['mrp'] ?? m['price'] ?? 0).toInt(),
      stock: (m['stock'] ?? 0).toInt(),
    );
  }
}

class Shop {
  final String id, name, emoji, category, village, ownerUid, etaText;
  final double rating;
  final double? lat, lng;
  final bool isOpen;
  const Shop({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.village,
    required this.ownerUid,
    required this.etaText,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.isOpen,
  });

  factory Shop.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Shop(
      id: d.id,
      name: m['name'] ?? '',
      emoji: m['emoji'] ?? '🏪',
      category: m['category'] ?? '',
      village: m['village'] ?? '',
      ownerUid: m['ownerUid'] ?? '',
      etaText: m['etaText'] ?? '30–40 mins',
      rating: (m['rating'] ?? 4.5).toDouble(),
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      isOpen: m['isOpen'] == true,
    );
  }
}

// Category icons stay local. Shops & products now come from Firestore.
const kCats = [
  ['🛒', 'Groceries'],
  ['🥬', 'Fresh Vegetables'],
  ['💊', 'Medicines'],
  ['🍬', 'Sweets & Snacks'],
  ['🏪', 'General Store'],
];
