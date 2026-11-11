import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services.dart';
import 'theme.dart';
import 'widgets.dart';

const _steps = ['placed', 'accepted', 'rider_assigned', 'out_for_delivery', 'delivered'];
const _titles = ['Order Placed', 'Shop Accepted & Packing', 'Delivery Boy Assigned', 'Out for Delivery', 'Delivered Successfully'];

class TrackingScreen extends StatefulWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {})); // drives the 2-min cancel countdown
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _report() {
    showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(padding: EdgeInsets.all(16), child: Text('Report an issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              for (final t in ['Wrong item', 'Damaged item', 'Item missing'])
                ListTile(
                    title: Text(t),
                    onTap: () async {
                      Navigator.pop(context);
                      await Db().reportIssue(widget.orderId, FirebaseAuth.instance.currentUser!.uid, t);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent. The shop will contact you.')));
                    }),
            ])));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: Db().watchOrder(widget.orderId),
          builder: (c, snap) {
            if (!snap.hasData || !snap.data!.exists) return const Center(child: CircularProgressIndicator());
            final o = snap.data!.data()!;
            final st = o['status'] as String;
            final cur = _steps.indexOf(st);
            final created = (o['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final left = 120 - DateTime.now().difference(created).inSeconds;
            final canCancel = st == 'placed' && left > 0;
            return ListView(padding: const EdgeInsets.all(16), children: [
              AppCard(
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Order #${widget.orderId.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${o['shopName'] ?? ''} · ₹${o['total']} · ${o['paymentMethod'] == 'cod' ? 'COD' : 'UPI'}', style: const TextStyle(color: kMuted)),
              ])),
              const SizedBox(height: 14),
              if (st == 'rejected')
                AppCard(child: Padding(padding: const EdgeInsets.all(8), child: Text('❌ The shop could not accept your order.\nReason: ${o['rejectReason'] ?? 'Not specified'}', style: const TextStyle(fontWeight: FontWeight.w700))))
              else if (st == 'cancelled')
                const AppCard(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('❌ Order Cancelled', style: TextStyle(fontWeight: FontWeight.w800)))))
              else
                AppCard(
                    child: Column(children: [
                  for (var i = 0; i < _steps.length; i++)
                    _StepRow(
                      title: (i == 1 && o['packed'] == true) ? 'Packed – waiting for delivery boy' : _titles[i],
                      done: i < cur || st == 'delivered',
                      current: i == cur && st != 'delivered',
                      last: i == _steps.length - 1,
                      trailing: i == 2 && cur >= 2 && o['riderName'] != null
                          ? Row(children: [
                              Text('${o['riderName']}', style: const TextStyle(color: kMuted)),
                              IconButton(icon: const Icon(Icons.call, color: kGreen), onPressed: () => launchUrl(Uri.parse('tel:${o['riderPhone']}'))),
                            ])
                          : null,
                    ),
                  if (st == 'out_for_delivery')
                    Container(
                        height: 140,
                        margin: const EdgeInsets.only(top: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFFE6F7EC), borderRadius: BorderRadius.circular(14)),
                        child: const Text('🛵  Live map (Google Maps – next step)', style: TextStyle(color: kMuted))),
                ])),
              const SizedBox(height: 14),
              if (canCancel) BigButton('Cancel Order (${left}s left)', () => Db().cancelOrder(widget.orderId), color: kRed, outlined: true),
              const SizedBox(height: 10),
              BigButton('⚠️ Report wrong or damaged item (Return/Replace)', _report, outlined: true),
            ]);
          },
        ),
      );
}

class _StepRow extends StatelessWidget {
  final String title;
  final bool done, current, last;
  final Widget? trailing;
  const _StepRow({required this.title, required this.done, required this.current, required this.last, this.trailing});
  @override
  Widget build(BuildContext context) {
    final col = done ? kGreen : current ? kBlue : kBorder;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
            width: 30,
            child: Column(children: [
              CircleAvatar(radius: 13, backgroundColor: col, child: Icon(done ? Icons.check : Icons.circle, size: done ? 16 : 8, color: Colors.white)),
              if (!last) Expanded(child: Container(width: 2, color: done ? kGreen : kBorder)),
            ])),
        const SizedBox(width: 12),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: done || current ? kText : kMuted))),
                  if (trailing != null) trailing!,
                ]))),
      ]),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: Db().myOrders(FirebaseAuth.instance.currentUser!.uid),
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final docs = s.data!.docs.toList()
              ..sort((a, b) {
                final x = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 1 << 50;
                final y = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 1 << 50;
                return y.compareTo(x);
              });
            if (docs.isEmpty) return const Center(child: Text('No orders yet', style: TextStyle(color: kMuted)));
            return ListView(padding: const EdgeInsets.all(16), children: [
              for (final d in docs)
                Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(orderId: d.id))),
                        child: AppCard(
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('#${d.id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text('${(d['items'] as List).length} item(s) · ₹${d['total']}', style: const TextStyle(color: kMuted)),
                          ]),
                          Text((d['status'] as String).replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w700, color: kBlue)),
                        ])))),
            ]);
          },
        ),
      );
}
