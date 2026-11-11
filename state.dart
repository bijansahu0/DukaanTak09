import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'catalog.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final CatalogState cat;
  AppState(this.cat) {
    cat.addListener(notifyListeners); // cart totals follow live prices/stock
  }

  final Map<String, int> cart = {};
  Map<String, dynamic> profile = {};

  int qty(String id) => cart[id] ?? 0;
  int get count => cart.values.fold(0, (a, b) => a + b);
  List<Product> get items => cart.keys.map((id) => cat.product(id)).whereType<Product>().toList();
  int get itemTotal => items.fold(0, (a, p) => a + p.price * qty(p.id));

  // One order = one shop.
  String? get shopId => items.isEmpty ? null : items.first.shopId;
  Shop? get shop => shopId == null ? null : cat.shop(shopId!);
  bool canAdd(Product p) => cart.isEmpty || shopId == p.shopId;

  /// Approx. road distance in km (straight line x 1.3). -1 if unknown.
  double kmTo(Shop s) {
    final la = profile['lat'], ln = profile['lng'];
    if (s.lat == null || s.lng == null || la == null || ln == null) return -1;
    final m = Geolocator.distanceBetween(s.lat!, s.lng!, (la as num).toDouble(), (ln as num).toDouble());
    return (m / 1000 * 1.3 * 10).round() / 10;
  }

  double get distanceKm {
    final s = shop;
    if (s == null) return 0;
    final k = kmTo(s);
    return k < 0 ? 2.0 : (k < 0.5 ? 0.5 : k);
  }

  int get fee => cart.isEmpty ? 0 : cat.feeBase + (distanceKm * cat.feePerKm).round();
  int get total => itemTotal + fee;

  void change(String id, int d) {
    final max = cat.product(id)?.stock ?? 0;
    var n = qty(id) + d;
    if (n > max) n = max;
    if (n <= 0) {
      cart.remove(id);
    } else {
      cart[id] = n;
    }
    notifyListeners();
  }

  /// Returns an error message if the cart can't be ordered right now.
  String? validateCart() {
    final sh = shop;
    if (sh == null || cart.isEmpty) return 'Your bag is empty';
    if (items.length != cart.length) return 'Some items are no longer available';
    if (!sh.isOpen) return '${sh.name} is closed right now';
    for (final p in items) {
      if (qty(p.id) > p.stock) return '${p.name}: only ${p.stock} left in stock';
    }
    if (profile['landmark'] == null) return 'Please add your landmark first';
    return null;
  }

  void clear() {
    cart.clear();
    notifyListeners();
  }

  void setProfile(Map<String, dynamic> p) {
    profile = p;
    notifyListeners();
  }

  void reset() {
    cart.clear();
    profile = {};
    notifyListeners();
  }
}
