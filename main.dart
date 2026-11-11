import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_controller.dart';
import 'auth_screens.dart';
import 'catalog.dart';
import 'services.dart';
import 'shell.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // reads android/app/google-services.json
  final catalog = CatalogState();
  final app = AppState(catalog);
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider.value(value: catalog),
    ChangeNotifierProvider.value(value: app),
    ChangeNotifierProvider(create: (_) => AuthController()),
  ], child: const DukaanTakApp()));
}

class DukaanTakApp extends StatelessWidget {
  const DukaanTakApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'DukaanTak',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Boot());
}

/// Shows splash for ~2s, then decides: login -> profile setup -> app.
class Boot extends StatefulWidget {
  const Boot({super.key});
  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _ready
          ? StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (c, s) {
                if (s.connectionState == ConnectionState.waiting) return const SplashScreen();
                if (s.data == null) return const MobileScreen();
                return ProfileGate(uid: s.data!.uid, key: ValueKey(s.data!.uid));
              })
          : const SplashScreen());
}

class ProfileGate extends StatefulWidget {
  final String uid;
  const ProfileGate({super.key, required this.uid});
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<Map<String, dynamic>?> _f;
  @override
  void initState() {
    super.initState();
    _f = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final state = context.read<AppState>();
    final p = await Db().getProfile(widget.uid);
    if (p != null && p['landmark'] != null) state.setProfile(p);
    return p;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
      future: _f,
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (s.hasError) {
          return Scaffold(
              body: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off, size: 56, color: kMuted),
                        const SizedBox(height: 12),
                        const Text('Could not load your profile.\nPlease check your internet connection.', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: () => setState(() => _f = _load()), child: const Text('Retry')),
                        TextButton(onPressed: () => context.read<AuthController>().signOut(), child: const Text('Logout')),
                      ]))));
        }
        final p = s.data;
        if (p == null || p['landmark'] == null) {
          return SetupScreen(onDone: () => setState(() => _f = _load()));
        }
        return const Shell();
      });
}
