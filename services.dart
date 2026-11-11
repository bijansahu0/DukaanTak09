import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'models.dart';

/// Turns Firebase error codes into messages a villager can understand.
String friendlyAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-phone-number':
      return 'That mobile number looks invalid. Please check it.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a few minutes and try again.';
    case 'quota-exceeded':
      return 'OTP limit reached for now. Please try again later.';
    case 'network-request-failed':
      return 'No internet connection. Please check and try again.';
    case 'invalid-verification-code':
      return 'Wrong OTP. Please try again.';
    case 'session-expired':
    case 'missing-verification-id':
      return 'OTP expired. Please tap Resend OTP.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact support.';
    case 'account-exists-with-different-credential':
      return 'This email is already used with another sign-in method.';
    case 'app-not-authorized':
    case 'invalid-app-credential':
    case 'missing-client-identifier':
      return 'This app is not authorised for sign-in yet (Firebase SHA key). Please contact support.';
    default:
      return e.message ?? 'Something went wrong. Please try again.';
  }
}

class AuthService {
  final _a = FirebaseAuth.instance;
  final _google = GoogleSignIn();
  String? _vid;
  int? _token;

  Future<void> sendOtp(String phone,
      {required VoidCallback onSent,
      required void Function(String) onError,
      VoidCallback? onAuto}) async {
    await _a.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 30),
      forceResendingToken: _token,
      verificationCompleted: (cred) async {
        try {
          await _a.signInWithCredential(cred); // instant / auto-retrieval
          onAuto?.call();
        } on FirebaseAuthException catch (e) {
          onError(friendlyAuthError(e));
        }
      },
      verificationFailed: (e) => onError(friendlyAuthError(e)),
      codeSent: (id, token) {
        _vid = id;
        _token = token;
        onSent();
      },
      codeAutoRetrievalTimeout: (id) => _vid = id,
    );
  }

  Future<void> verify(String code) {
    final id = _vid;
    if (id == null) {
      throw FirebaseAuthException(code: 'missing-verification-id');
    }
    return _a.signInWithCredential(PhoneAuthProvider.credential(verificationId: id, smsCode: code));
  }

  /// Returns false if the user simply closed the Google account picker.
  Future<bool> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return false;
    final auth = await account.authentication;
    final cred = GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken);
    await _a.signInWithCredential(cred);
    return true;
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _a.signOut();
  }
}

class Db {
  final _f = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _f.collection('users').doc(uid);

  Future<Map<String, dynamic>?> getProfile(String uid) async =>
      (await _user(uid).get()).data();

  Future<void> saveProfile(String uid, Map<String, dynamic> d) =>
      _user(uid).set({...d, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  /// Creates an order. This document is the single shared record that the
  /// Partner, Rider and Admin apps all read and update (see DATA_MODEL.md).
  Future<String> placeOrder({
    required String uid,
    required Map<String, dynamic> profile,
    required Shop shop,
    required List<Map<String, dynamic>> items,
    required int itemTotal,
    required int fee,
    required String payment, // 'upi' | 'cod'
  }) async {
    final ref = _f.collection('orders').doc();
    await ref.set({
      'customerId': uid,
      'customerName': profile['name'],
      'customerPhone': profile['phone'],
      'address': {
        'village': profile['village'],
        'landmark': profile['landmark'],
        'lat': profile['lat'],
        'lng': profile['lng'],
      },
      'shopId': shop.id,
      'shopName': shop.name,
      'vendorId': shop.ownerUid, // lets the shopkeeper query "my orders"
      'items': items,
      'itemTotal': itemTotal,
      'deliveryFee': fee,
      'total': itemTotal + fee,
      'paymentMethod': payment,
      'paymentStatus': payment == 'cod' ? 'cash_on_delivery' : 'pending_online',
      'status': 'placed',
      'packed': false,
      'riderId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrder(String id) =>
      _f.collection('orders').doc(id).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> myOrders(String uid) =>
      _f.collection('orders').where('customerId', isEqualTo: uid).snapshots();

  Future<void> cancelOrder(String id) =>
      _f.collection('orders').doc(id).update({'status': 'cancelled'});

  Future<void> reportIssue(String orderId, String uid, String type) =>
      _f.collection('issues').add({
        'orderId': orderId,
        'customerId': uid,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
