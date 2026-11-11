import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_controller.dart';
import 'auth_screens.dart';
import 'catalog.dart';
import 'cart_checkout.dart';
import 'models.dart';
import 'services.dart';
import 'state.dart';
import 'theme.dart';
import 'tracking.dart';
import 'widgets.dart';

const kHelplineWhatsApp = '919000000000'; // TODO: your WhatsApp number with country code

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  @override
  void initState() {
    super.initState();
    context.read<CatalogState>().start(); // live shops & products
  }

  void _go(int i) => setState(() => _i = i);

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AppState>().count;
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        HomeTab(onSearch: () => _go(1)),
        const SearchTab(),
        CartTab(onShop: () => _go(0)),
        const ProfileTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: _go,
        backgroundColor: Colors.white,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.shopping_bag_outlined)),
              label: 'Cart'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final VoidCallback onSearch;
  const HomeTab({super.key, required this.onSearch});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cat = context.watch<CatalogState>();
    final p = app.profile;
    return SafeArea(
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Deliver to', style: TextStyle(color: kMuted, fontSize: 13)),
                Text('📍 ${p['village'] ?? 'Your village'} ▾', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ]),
              IconButton.outlined(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
            ]),
            const SizedBox(height: 16),
            InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder, width: 1.5)),
                child: const Row(children: [
                  Icon(Icons.search, color: kMuted),
                  SizedBox(width: 8),
                  Expanded(child: Text('Search groceries, medicines, sweets, clothes...', overflow: TextOverflow.ellipsis, style: TextStyle(color: kMuted))),
                ]),
              ),
            ),
            sectionTitle('Categories'),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kCats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 78,
                  child: Column(children: [
                    Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: kBlueSoft, borderRadius: BorderRadius.circular(20)),
                        child: Text(kCats[i][0], style: const TextStyle(fontSize: 30))),
                    const SizedBox(height: 6),
                    Text(kCats[i][1], textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
            sectionTitle('Nearby Popular Shops'),
            if (cat.shops.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                      cat.error != null ? 'Could not load shops: ${cat.error}' : (cat.loaded ? 'No shops available in your area yet.' : 'Loading shops…'),
                      style: const TextStyle(color: kMuted)))
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cat.shops.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final s = cat.shops[i];
                    final km = app.kmTo(s);
                    final kmText = km >= 0 ? '  ·  ${km.toStringAsFixed(1)} km' : '';
                    return Opacity(
                      opacity: s.isOpen ? 1 : .5,
                      child: SizedBox(
                        width: 230,
                        child: AppCard(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                                height: 70,
                                width: double.infinity,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: const LinearGradient(colors: [Color(0xFFE6F7EC), kBlueSoft])),
                                child: Text(s.emoji, style: const TextStyle(fontSize: 38))),
                            const SizedBox(height: 8),
                            Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(s.isOpen ? '★ ${s.rating.toStringAsFixed(1)}  ·  🕒 ${s.etaText}$kmText' : 'Closed right now',
                                style: const TextStyle(color: kMuted, fontSize: 12)),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            
sectionTitle('Daily Essentials'),
          ])),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .66),
            itemCount: cat.available.length,
            itemBuilder: (_, i) => ProductCard(cat.available[i]),
          ),
        ),
      ]),
    );
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});
  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final r = context.watch<CatalogState>().available.where((p) => p.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Search', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search groceries, medicines, sweets, clothes...')),
          const SizedBox(height: 12),
          Expanded(
            child: r.isEmpty
                ? const Center(child: Text('No products found', style: TextStyle(color: kMuted)))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .66),
                    itemCount: r.length,
                    itemBuilder: (_, i) => ProductCard(r[i])),
          ),
        ]),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppState>().profile;
    Widget item(IconData i, String t, VoidCallback f, {Color? c}) => ListTile(
        leading: Icon(i, color: c ?? kText), title: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w600)), trailing: const Icon(Icons.chevron_right), onTap: f);
    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            const CircleAvatar(radius: 30, backgroundColor: kBlueSoft, child: Text('🙂', style: TextStyle(fontSize: 28))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('✅ ${p['phone'] ?? ''} verified', style: const TextStyle(color: kMuted, fontSize: 13)),
              Text('📍 ${p['village'] ?? ''} · Near ${p['landmark'] ?? ''}', style: const TextStyle(color: kMuted, fontSize: 13)),
            ])),
          ]),
        ),
        const SizedBox(height: 8),
        item(Icons.inventory_2_outlined, 'My Orders', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
        item(Icons.home_outlined, 'Saved Addresses',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => SetupScreen(editing: true, onDone: () => Navigator.pop(context))))),
        item(Icons.support_agent, 'Help & Support / WhatsApp Helpline',
            () => launchUrl(Uri.parse('https://wa.me/$kHelplineWhatsApp'), mode: LaunchMode.externalApplication)),
        item(Icons.description_outlined, 'Terms & Conditions', () {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                  title: const Text('Terms & Conditions'),
                  content: const Text('Add your terms here (or open a hosted page with url_launcher).'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
        }),
        item(Icons.logout, 'Logout', () async {
          context.read<CatalogState>().stop();
          context.read<AppState>().reset();
          await context.read<AuthController>().signOut();
        }, c: kRed),
        const SizedBox(height: 10),
        Text('uid: ${FirebaseAuth.instance.currentUser?.uid ?? ''}', textAlign: TextAlign.center, style: const TextStyle(color: kBorder, fontSize: 10)),
      ]),
    );
  }
}
