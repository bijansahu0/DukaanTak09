import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'services.dart';

/// All login state (phone OTP + Google) lives here, so the screens stay simple.
class AuthController extends ChangeNotifier {
  final AuthService _svc = AuthService();

  bool busy = false; // verifying an OTP
  bool googleBusy = false; // Google dialog / sign-in running
  bool codeSent = false;
  String? error;
  int resendLeft = 0;
  Timer? _timer;

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  // ---------- Google ----------
  /// Returns true when signed in. Success also flips FirebaseAuth's
  /// authStateChanges stream, which moves the app past the login screen.
  Future<bool> signInWithGoogle() async {
    googleBusy = true;
    error = null;
    notifyListeners();
    try {
      return await _svc.signInWithGoogle(); // false = user closed the dialog
    } on FirebaseAuthException catch (e) {
      error = friendlyAuthError(e);
    } on PlatformException catch (e) {
      error = _googlePlatformError(e);
    } catch (_) {
      error = 'Google sign-in failed. Please check your internet and try again.';
    } finally {
      googleBusy = false;
      notifyListeners();
    }
    return false;
  }

  String _googlePlatformError(PlatformException e) {
    final m = '${e.code} ${e.message}';
    if (m.contains('network_error')) return 'No internet connection. Please try again.';
    if (m.contains('sign_in_canceled')) return '';
    // ApiException 10 / 12500 = SHA-1 key or Google provider not set up in Firebase
    return 'Google sign-in is not set up for this app yet (Firebase SHA-1 key). Please use mobile OTP.';
  }

  // ---------- Phone OTP ----------
  void sendOtp(String phone, {required VoidCallback onSignedIn}) {
    error = null;
    codeSent = false;
    _startTimer();
    notifyListeners();
    _svc
        .sendOtp(phone, onSent: () {
          codeSent = true;
          notifyListeners();
        }, onError: (m) {
          error = m;
          _stopTimer(); // let the user retry straight away
          notifyListeners();
        }, onAuto: onSignedIn)
        .catchError((Object e) {
      error = e is FirebaseAuthException ? friendlyAuthError(e) : 'Could not send OTP. Please try again.';
      _stopTimer();
      notifyListeners();
    });
  }

  Future<bool> verifyOtp(String code) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _svc.verify(code);
      return true;
    } on FirebaseAuthException catch (e) {
      error = friendlyAuthError(e);
    } catch (_) {
      error = 'Could not verify the code. Please try again.';
    } finally {
      busy = false;
      notifyListeners();
    }
    return false;
  }

  void _startTimer() {
    _timer?.cancel();
    resendLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      resendLeft = resendLeft > 0 ? resendLeft - 1 : 0;
      if (resendLeft == 0) t.cancel();
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    resendLeft = 0;
  }

  /// Called when the OTP screen closes (no notification: screen is going away).
  void resetOtp() {
    _stopTimer();
    codeSent = false;
    busy = false;
    error = null;
  }

  Future<void> signOut() => _svc.signOut();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
