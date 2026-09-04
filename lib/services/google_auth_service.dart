import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'session_service.dart';

class GoogleAuthResult {
  final UserModel? profile;
  final String? name;
  final String? email;
  final String? photoUrl;

  GoogleAuthResult.existing(this.profile)
      : name = null,
        email = null,
        photoUrl = null;

  GoogleAuthResult.newUser({
    required this.name,
    required this.email,
    this.photoUrl,
  }) : profile = null;
}

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<GoogleAuthResult?> signInWithGoogle({required String role}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return null;
      }

      await firebaseUser.getIdToken(true);

      if (firebaseUser.displayName != null && googleUser.displayName != null) {
        await firebaseUser.updateDisplayName(googleUser.displayName);
      }
      if (googleUser.photoUrl != null) {
        await firebaseUser.updatePhotoURL(googleUser.photoUrl);
      }

      final profile = await AuthService.getUserProfileOnce(firebaseUser.uid);

      if (profile != null) {
        if (profile.role != role) {
          await AuthService.updateUserRole(role);
        }
        await SessionService.save(profile.role);
        await NotificationService.syncTokenForCurrentUser();
        return GoogleAuthResult.existing(profile);
      }

      return GoogleAuthResult.newUser(
        name: googleUser.displayName ?? firebaseUser.displayName ?? 'Google User',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl ?? firebaseUser.photoURL,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'account-exists-with-different-credential') {
        throw FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message:
              'An account already exists with this email. Please sign in with your original method first.',
        );
      }
      rethrow;
    } catch (error) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google sign-in failed: $error',
      );
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await AuthService.signOut();
  }
}
