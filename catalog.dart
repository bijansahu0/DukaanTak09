import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';

/// Live shops, products and app-wide settings from Firestore.
/// Started after login (Shell), stopped on logout.
class CatalogState extends ChangeNotifier {
  List<Shop> shops = [];
  List<Product> products = [];
  int feeBase = 15; // overridden by Firestore doc config/app
  int feePerKm = 5;
  bool loaded = false;
  String? error;
  StreamSubscription? _a, _b, _c;

  void start() {
    if (_a != null) return;
    final f = FirebaseFirestore.instance;
    _a = f.collection('shops').where('active', isEqualTo: true).snapshots().listen((s) {
      shops = s.docs.map(Shop.fromDoc).toList();
      loaded = true;
      error = null;
      notifyListeners();
    }, onError: _fail);
    _b = f.collection('products').where('active', isEqualTo: true).snapshots().listen((s) {
      products = s.docs.map(Product.fromDoc).toList();
      notifyListeners();
    }, onError: _fail);
    _c = f.collection('config').doc('app').snapshots().listen((d) {
      final m = d.data();
      if (m != null) {
        feeBase = (m['feeBase'] ?? 15).toInt();
        feePerKm = (m['feePerKm'] ?? 5).toInt();
        notifyListeners();
      }
    }, onError: _fail);
  }

  void _fail(Object e) {
    error = e.toString();
    notifyListeners();
  }

  void stop() {
    _a?.cancel();
    _b?.cancel();
    _c?.cancel();
    _a = _b = _c = null;
    shops = [];
    products = [];
    loaded = false;
  }

  Shop? shop(String id) {
    for (final s in shops) {
      if (s.id == id) return s;
    }
    return null;
  }

  Product? product(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Products of shops that are currently open.
  List<Product> get available {
    final open = shops.where((s) => s.isOpen).map((s) => s.id).toSet();
    return products.where((p) => open.contains(p.shopId)).toList();
  }
}
