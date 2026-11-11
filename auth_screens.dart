import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'auth_controller.dart';
import 'services.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

/// The DukaanTak logo (assets/icon/app_icon.png) with an emoji fallback.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 92});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * .28),
        child: Image.asset('assets/icon/app_icon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                color: kBlue,
                child: Text('🛍️', style: TextStyle(fontSize: size * .5)))),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: kRed, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: kRed, fontWeight: FontWeight.w600))),
        ]),
      );
}

// ───────────────────────── Splash ─────────────────────────
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A56DB), Color(0xFF0E3A9E), Color(0xFF16A34A)])),
          child: SafeArea(
            child: Column(children: [
              const Spacer(flex: 3),
              Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 30, offset: const Offset(0, 12)),
                  ]),
                  child: const BrandLogo(size: 112)),
              const SizedBox(height: 22),
              const Text('DukaanTak', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: .5)),
              const SizedBox(height: 8),
              const Text('Aapke Bazaar Se Aapke Ghar Tak', style: TextStyle(color: Colors.white70, fontSize: 15)),
              const Spacer(flex: 3),
              const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white70)),
              const SizedBox(height: 36),
            ]),
          ),
        ),
      );
}

// ───────────────────────── Mobile + Google ─────────────────────────
class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});
  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final valid = _c.text.length == 10;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: BrandLogo(size: 64)),
          const SizedBox(height: 22),
          const Text('Namaste! 🙏', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kText)),
          const SizedBox(height: 6),
          const Text('Enter your mobile number to get started', style: TextStyle(color: kMuted)),
          const SizedBox(height: 26),
          TextField(
            controller: _c,
            keyboardType: TextInputType.number,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              auth.clearError();
              setState(() {});
            },
            decoration: const InputDecoration(prefixText: '+91  ', hintText: '10-digit mobile number', counterText: ''),
          ),
          const SizedBox(height: 16),
          BigButton('Continue', valid && !auth.googleBusy ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: _c.text))) : null),
          if (auth.error != null && auth.error!.isNotEmpty) _ErrorBanner(auth.error!),
          const SizedBox(height: 22),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: kMuted))),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: auth.googleBusy ? null : () => context.read<AuthController>().signInWithGoogle(),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kText,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: kBorder, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: auth.googleBusy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                      SizedBox(width: 12),
                      Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ]),
            ),
          ),
          const SizedBox(height: 24),
          const Text('By continuing you agree to our Terms & Conditions', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 12)),
        ]),
      ),
    );
  }
}

// ───────────────────────── OTP ─────────────────────────
class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _c = TextEditingController();
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _auth.resetOtp();
    _c.dispose();
    super.dispose();
  }

  void _send() {
    _c.clear();
    _auth.sendOtp(widget.phone, onSignedIn: _done);
  }

  void _done() {
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final ok = await _auth.verifyOtp(_c.text);
    if (!mounted) return;
    if (ok) {
      _done();
    } else {
      _c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Verify OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kText)),
          const SizedBox(height: 6),
          Text('We sent a 6-digit code to +91 ${widget.phone}', style: const TextStyle(color: kMuted)),
          const SizedBox(height: 28),
          TextField(
            controller: _c,
            autofocus: true,
            enabled: !a.busy,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 14),
            decoration: const InputDecoration(counterText: '', hintText: '------'),
            onChanged: (v) {
              if (a.error != null) a.clearError();
              if (v.length == 6 && !a.busy) _verify(); // auto-verify
            },
          ),
          if (a.error != null && a.error!.isNotEmpty) _ErrorBanner(a.error!),
          const SizedBox(height: 20),
          Center(
              child: a.busy
                  ? const CircularProgressIndicator()
                  : a.resendLeft > 0
                      ? Text('Resend code in ${a.resendLeft}s', style: const TextStyle(color: kMuted))
                      : TextButton(onPressed: _send, child: const Text('Resend OTP', style: TextStyle(fontWeight: FontWeight.w700)))),
          const SizedBox(height: 6),
          Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Change mobile number'))),
        ]),
      ),
    );
  }
}

// ───────────────────────── Profile setup ─────────────────────────
/// First-time profile setup AND "Edit address" (pass editing: true, onDone: pop).
class SetupScreen extends StatefulWidget {
  final VoidCallback onDone;
  final bool editing;
  const SetupScreen({super.key, required this.onDone, this.editing = false});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController(), _phone = TextEditingController();
  final _village = TextEditingController(), _lm = TextEditingController();
  double? _lat, _lng;
  String _gps = '';
  bool _gpsBusy = false, _gpsNeedsSettings = false, _saving = false;
  String? _err;
  late final bool _needPhone; // Google users have no verified phone yet

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final p = context.read<AppState>().profile;
    _needPhone = (user?.phoneNumber ?? '').isEmpty;
    _name.text = '${p['name'] ?? user?.displayName ?? ''}';
    _village.text = '${p['village'] ?? ''}';
    _lm.text = '${p['landmark'] ?? ''}';
    final digits = '${p['phone'] ?? ''}'.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) _phone.text = digits.substring(digits.length - 10);
    _lat = (p['lat'] as num?)?.toDouble();
    _lng = (p['lng'] as num?)?.toDouble();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _village, _lm]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _village.text.trim().isNotEmpty &&
      _lm.text.trim().isNotEmpty &&
      (!_needPhone || _phone.text.length == 10);

  Future<void> _detect() async {
    setState(() {
      _gpsBusy = true;
      _gps = '';
      _gpsNeedsSettings = false;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _gps = 'Please turn on Location (GPS) in your phone settings, then try again.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _gps = 'Location permission is blocked. Allow it in app settings, or just type your village below.';
          _gpsNeedsSettings = true;
        });
        return;
      }
      if (perm == LocationPermission.denied) {
        setState(() => _gps = 'Location permission denied – you can still type your village and landmark.');
        return;
      }
      final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
      setState(() {
        _lat = p.latitude;
        _lng = p.longitude;
        _gps = '✅ Location detected (${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})';
      });
    } on TimeoutException {
      setState(() => _gps = 'Could not get a GPS signal. Please step outside and try again.');
    } catch (_) {
      setState(() => _gps = 'Could not detect location. You can still type your village and landmark.');
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final phone = (user.phoneNumber ?? '').isNotEmpty ? user.phoneNumber : '+91${_phone.text.trim()}';
      final data = <String, dynamic>{
        'name': _name.text.trim(),
        'phone': phone,
        'email': user.email,
        'village': _village.text.trim(),
        'landmark': _lm.text.trim(),
        'lat': _lat,
        'lng': _lng,
      };
      await Db().saveProfile(user.uid, data);
      if (!mounted) return;
      context.read<AppState>().setProfile(data);
      widget.onDone();
    } on FirebaseException catch (e) {
      if (mounted) setState(() => _err = e.code == 'unavailable' ? 'No internet connection. Please try again.' : 'Could not save your details (${e.code}). Please try again.');
    } catch (_) {
      if (mounted) setState(() => _err = 'Could not save your details. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: kMuted, fontSize: 13)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.editing ? AppBar(title: const Text('Edit address')) : null,
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (!widget.editing) ...[
              const SizedBox(height: 10),
              const Text('Set up your profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kText)),
              const SizedBox(height: 6),
              const Text('So shops can find you easily', style: TextStyle(color: kMuted)),
            ],
            _label('Full name'),
            TextField(controller: _name, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'e.g. Rahul Mondal')),
            if (_needPhone) ...[
              _label('Mobile number (for delivery calls)'),
              TextField(
                  controller: _phone,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(prefixText: '+91  ', hintText: '10-digit mobile number', counterText: '')),
            ],
            _label('Village / Area name'),
            TextField(controller: _village, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'e.g. Maheshpur')),
            const SizedBox(height: 16),
            _gpsBusy
                ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator()))
                : BigButton('📍 Detect Current Location (GPS)', _detect, outlined: true),
            if (_gps.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_gps, style: const TextStyle(color: kMuted))),
            if (_gpsNeedsSettings) TextButton(onPressed: Geolocator.openAppSettings, child: const Text('Open app settings')),
            _label('Nearby landmark *'),
            TextField(
                controller: _lm,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'e.g. Near Primary School, Kali Mandir, Main Road')),
            if (_err != null) _ErrorBanner(_err!),
            const SizedBox(height: 24),
            _saving ? const Center(child: CircularProgressIndicator()) : BigButton('Save & Start Shopping', _valid ? _save : null, color: kGreen),
            const SizedBox(height: 12),
          ]),
        ),
      );
}
