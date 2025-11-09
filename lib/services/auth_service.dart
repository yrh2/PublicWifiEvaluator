import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      print('🔥 Auth state changed: ${user?.email ?? 'null'}');
      notifyListeners();
    });
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔐 Starting login for: $email');

      // Add timeout to prevent hanging
      final credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏰ Login timeout after 30 seconds');
              throw 'Login timed out. Please check your internet connection and try again.';
            },
          );

      print('✅ Login successful for: ${credential.user?.email}');
      print('🔥 User UID: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unexpected login error: $e');
      throw 'Login failed: $e';
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw 'Google sign-in failed: $e';
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('DEBUG: Starting password reset for email: $email');
      print('DEBUG: Firebase Auth instance: ${_auth.toString()}');
      print(
        'DEBUG: Current user: ${_auth.currentUser?.email ?? 'No current user'}',
      );

      await _auth.sendPasswordResetEmail(email: email);

      print('SUCCESS: Password reset email request completed for: $email');
      print(
        'DEBUG: Check Firebase Console > Authentication > Users to verify email exists',
      );
    } on FirebaseAuthException catch (e) {
      print('FIREBASE AUTH ERROR: Code: ${e.code}');
      print('FIREBASE AUTH ERROR: Message: ${e.message}');
      print('FIREBASE AUTH ERROR: Details: ${e.toString()}');
      throw _handleAuthException(e);
    } catch (e) {
      print('UNEXPECTED ERROR: $e');
      print('UNEXPECTED ERROR Type: ${e.runtimeType}');
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      case 'invalid-api-key':
        return 'Firebase API key is invalid. Please check your configuration.';
      case 'api-key-not-valid':
        return 'Firebase API key is not valid. Please enable Authentication in Firebase Console.';
      case 'auth/invalid-email':
        return 'Please enter a valid email address.';
      case 'auth/user-not-found':
        return 'No account found with this email address.';
      case 'auth/quota-exceeded':
        return 'Email quota exceeded. Please try again later.';
      case 'auth/email-already-in-use':
        return 'An account with this email already exists.';
      default:
        return 'An unexpected error occurred: ${e.message}';
    }
  }
}
