import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'state.dart';
import 'theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder)),
        child: child,
      );
}

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool outlined;
  const BigButton(this.label, this.onTap,
      {super.key, this.color = kBlue, this.outlined = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: outlined
            ? OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))
            : FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
      );
}

Widget sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText)));

class QtyStepper extends StatelessWidget {
  final String id;
  const QtyStepper(this.id, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Widget b(IconData i, int d) => InkWell(
        onTap: () => s.change(id, d),
        child: SizedBox(width: 32, height: 32, child: Icon(i, color: Colors.white, size: 18)));
    return Container(
      decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        b(Icons.remove, -1),
        Text('${s.qty(id)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        b(Icons.add, 1),
      ]),
    );
  }
}

Future<void> addToCart(BuildContext context, Product p) async {
  final s = context.read<AppState>();
  if (p.stock <= 0) return;
  if (!s.canAdd(p)) {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Start a new bag?'),
              content: Text('Your bag has items from ${s.shop?.name ?? 'another shop'}. Each order can contain items from one shop only.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep old bag')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start new')),
              ],
            ));
    if (ok != true) return;
    s.clear();
  }
  s.change(p.id, 1);
}

class ProductCard extends StatelessWidget {
  final Product p;
  const ProductCard(this.p, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final out = p.stock <= 0;
    final low = !out && p.stock <= 5;
    final note = low ? '${p.weight} · only ${p.stock} left' : p.weight;
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(
              height: 92,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kBlueSoft, borderRadius: BorderRadius.circular(12)),
              child: Opacity(opacity: out ? .35 : 1, child: Text(p.emoji, style: const TextStyle(fontSize: 48)))),
          if (p.off > 0 && !out)
            Positioned(
                top: 6,
                left: 6,
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(8)),
                    child: Text('${p.off}% OFF', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
        ]),
        const SizedBox(height: 8),
        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: low ? const Color(0xFFEA580C) : kMuted, fontSize: 13)),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('₹${p.price}', style: const TextStyle(fontWeight: FontWeight.w800)),
            if (p.mrp > p.price) Text('₹${p.mrp}', style: const TextStyle(color: kMuted, fontSize: 12, decoration: TextDecoration.lineThrough)),
          ]),
          if (out)
            const Text('Out of stock', style: TextStyle(color: kRed, fontSize: 12, fontWeight: FontWeight.w700))
          else if (s.qty(p.id) == 0)
            OutlinedButton(
                onPressed: () => addToCart(context, p),
                style: OutlinedButton.styleFrom(
                    foregroundColor: kGreen,
                    side: const BorderSide(color: kGreen, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.w700)))
          else
            QtyStepper(p.id),
        ]),
      ]),
    );
  }
}
