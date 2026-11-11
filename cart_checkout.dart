import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_screens.dart';
import 'services.dart';
import 'state.dart';
import 'theme.dart';
import 'tracking.dart';
import 'widgets.dart';

class CartTab extends StatelessWidget {
  final VoidCallback onShop;
  const CartTab({super.key, required this.onShop});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.cart.isEmpty) {
      return SafeArea(
          child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🛒', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        const Text('Your bag is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const Text('Add items from nearby shops', style: TextStyle(color: kMuted)),
        const SizedBox(height: 16),
        FilledButton(onPressed: onShop, child: const Text('Start Shopping')),
      ])));
    }
    final p = s.profile;
    Widget line(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null, fontSize: bold ? 17 : null)),
          Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null, fontSize: bold ? 17 : null)),
        ]));
    return SafeArea(
      child: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('My Bag', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (final it in s.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(children: [
                    Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: kBlueSoft, borderRadius: BorderRadius.circular(12)),
                        child: Text(it.emoji, style: const TextStyle(fontSize: 30))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(it.weight, style: const TextStyle(color: kMuted, fontSize: 13)),
                      Text('₹${it.price * s.qty(it.id)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ])),
                    QtyStepper(it.id),
                  ]),
                ),
              ),
            sectionTitle('Bill Summary'),
            AppCard(
                child: Column(children: [
              line('Item Total', '₹${s.itemTotal}'),
              line('Delivery Fee (${s.distanceKm.toStringAsFixed(1)} km)', '₹${s.fee}'),
              const Divider(),
              line('Total Payable', '₹${s.total}', bold: true),
            ])),
            sectionTitle('Delivery Address'),
            AppCard(
                child: Row(children: [
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('📍 ${p['village'] ?? ''} · Near ${p['landmark'] ?? ''}', style: const TextStyle(color: kMuted)),
              ])),
              TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SetupScreen(editing: true, onDone: () => Navigator.pop(context)))),
                  child: const Text('Edit')),
            ])),
          ]),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: BigButton('Proceed to Checkout · ₹${s.total}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())))),
      ]),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _pay = 'upi';
  bool _busy = false;

  Widget _opt(String id, String title, String sub, {Widget? extra}) => GestureDetector(
        onTap: () => setState(() => _pay = id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _pay == id ? kBlueSoft : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _pay == id ? kBlue : kBorder, width: 1.5)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(_pay == id ? Icons.radio_button_checked : Icons.radio_button_off, color: _pay == id ? kBlue : kMuted),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(sub, style: const TextStyle(color: kMuted, fontSize: 13)),
              if (extra != null) extra,
            ])),
          ]),
        ),
      );

  Future<void> _place() async {
    final s = context.read<AppState>();
    final problem = s.validateCart();
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await Db().placeOrder(
        uid: FirebaseAuth.instance.currentUser!.uid,
        profile: s.profile,
        shop: s.shop!,
        items: s.items.map((p) => {'productId': p.id, 'name': p.name, 'weight': p.weight, 'price': p.price, 'qty': s.qty(p.id)}).toList(),
        itemTotal: s.itemTotal,
        fee: s.fee,
        payment: _pay,
      );
      s.clear();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuccessScreen(orderId: id)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not place order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Amount to pay', style: TextStyle(color: kMuted)),
          Text('₹${s.total}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ])),
        sectionTitle('Payment method'),
        _opt('upi', 'Online Payment (UPI)', 'GPay · PhonePe · Paytm · Razorpay (integration preview)'),
        _opt('cod', 'Cash on Delivery (COD)', 'Pay cash or scan delivery boy\'s UPI QR upon delivery.'),
      ]),
      bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _busy ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator())) : BigButton('Confirm Order', _place, color: kGreen))),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  final String orderId;
  const SuccessScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: const Icon(Icons.check_circle, size: 120, color: kGreen)),
            const SizedBox(height: 16),
            const Text('Order Placed!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Order #${orderId.substring(0, 6).toUpperCase()}', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 28),
            BigButton('Track Order', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TrackingScreen(orderId: orderId)))),
            const SizedBox(height: 10),
            BigButton('Continue Shopping', () => Navigator.of(context).popUntil((r) => r.isFirst), outlined: true),
          ]),
        )),
      );
}
