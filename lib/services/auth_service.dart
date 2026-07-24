import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'notification_service.dart';
import 'session_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;
  static bool get isLoggedIn => _auth.currentUser != null;

  static Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Failed to create user account.',
        );
      }

      await user.updateDisplayName(name);
      final normalizedPhone = _normalizeKenyanPhone(phone);
      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        phone: normalizedPhone,
        role: role,
        email: email.trim().toLowerCase(),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      await SessionService.save(role);
      await NotificationService.syncTokenForCurrentUser();
      return userModel;
    } on FirebaseAuthException catch (error) {
      throw _handleAuthError(error);
    } catch (error) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred: $error',
      );
    }
  }

  static Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'login-failed',
          message: 'Failed to sign in.',
        );
      }

      final profile = await getUserProfileOnce(user.uid);
      if (profile == null) {
        throw FirebaseAuthException(
          code: 'profile-not-found',
          message: 'Your account profile is incomplete. Please register again.',
        );
      }

      await SessionService.save(profile.role);
      await NotificationService.syncTokenForCurrentUser();
      return profile;
    } on FirebaseAuthException catch (error) {
      throw _handleAuthError(error);
    } catch (error) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred: $error',
      );
    }
  }

  static Future<UserModel?> getUserProfileOnce([String? uid]) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return null;
    final document = await _firestore.collection('users').doc(userId).get();
    final data = document.data();
    return data == null ? null : UserModel.fromMap(data, document.id);
  }

  static Future<UserModel> completePhoneProfile({
    required String name,
    required String role,
    String? neighborhood,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No authenticated phone user was found.',
      );
    }

    final model = UserModel(
      uid: user.uid,
      name: name.trim(),
      phone: user.phoneNumber ?? '',
      role: role,
      email: user.email,
      neighborhood: neighborhood,
      createdAt: DateTime.now(),
    );
    await user.updateDisplayName(model.name);
    await _firestore.collection('users').doc(user.uid).set(model.toMap());
    await SessionService.save(role);
    await NotificationService.syncTokenForCurrentUser();
    return model;
  }

  static Future<void> signOut() async {
    try {
      await NotificationService.deleteToken();
      await _auth.signOut();
      await SessionService.clear();
    } catch (error) {
      throw FirebaseAuthException(
        code: 'sign-out-failed',
        message: 'Failed to sign out: $error',
      );
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw _handleAuthError(error);
    }
  }

  static Stream<UserModel?> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : UserModel.fromMap(data, snapshot.id);
    });
  }

  static Future<void> updateUserProfile(UserModel user) async {
    if (_auth.currentUser?.uid != user.uid) {
      throw StateError('You can only update your own profile.');
    }
    await _firestore.collection('users').doc(user.uid).update({
      'name': user.name.trim(),
      'phone': user.phone.trim(),
      'email': user.email,
      'photoUrl': user.photoUrl,
      'neighborhood': user.neighborhood?.trim(),
      'lat': user.lat,
      'lng': user.lng,
      'skills': user.skills ?? const <String>[],
      'bio': user.bio?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
    await SessionService.clear();
  }

  static String _normalizeKenyanPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('254') && digits.length == 12) return '+$digits';
    if (digits.startsWith('0') && digits.length == 10) {
      return '+254${digits.substring(1)}';
    }
    if (digits.length == 9) return '+254$digits';
    return value.trim();
  }

  static FirebaseAuthException _handleAuthError(FirebaseAuthException error) {
    final message = switch (error.code) {
      'email-already-in-use' =>
        'An account already exists with this email address.',
      'weak-password' =>
        'Your password is too weak. Use at least six characters.',
      'invalid-email' => 'Enter a valid email address.',
      'user-not-found' ||
      'invalid-credential' => 'The email address or password is incorrect.',
      'wrong-password' => 'The password is incorrect. Please try again.',
      'user-disabled' =>
        'This account has been disabled. Contact support for assistance.',
      'too-many-requests' =>
        'Too many attempts. Please wait and try again later.',
      'operation-not-allowed' =>
        'This sign-in method is currently unavailable.',
      'network-request-failed' =>
        'A network error occurred. Check your connection and try again.',
      _ => error.message ?? 'Something went wrong. Please try again.',
    };
    return FirebaseAuthException(code: error.code, message: message);
  }
}
