import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

final supAuthProv = Provider((ref) => Supabase.instance.client.auth);

final authStateProvider = StreamProvider((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) => event.session);
});

final authControllerProvider = Provider((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref ref;
  AuthController(this.ref);

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Starting login for email: $email');

      final response = await ref.read(supAuthProv).signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('Login response: ${response.session?.user?.email}');

      if (response.session != null) {
        debugPrint('Login successful');
        return true;
      } else {
        debugPrint('Login failed: No session created');
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> logUp({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Starting signup for email: $email');

      final response = await ref.read(supAuthProv).signUp(
        email: email,
        password: password,
      );

      debugPrint('SignUp response: ${response.user?.email}');

      // Check if user was created (even without session due to email confirmation)
      if (response.user != null) {
        if (response.session != null) {
          debugPrint('SignUp successful with immediate session');
          return true;
        } else {
          debugPrint('SignUp successful - email confirmation required');
          return true; // User created but needs email confirmation
        }
      } else {
        debugPrint('SignUp failed: No user created');
        return false;
      }
    } catch (e) {
      debugPrint('SignUp error: $e');
      return false;
    }
  }

  // Fixed: Moved Google Sign-In inside AuthController class
  Future<bool> googleSignIn() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // IMPORTANT → use Web Client ID from Google Cloud
        serverClientId:
        "381063348704-crl2r9amlaer6v747t0hsurj89g076pi.apps.googleusercontent.com",
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Google Sign-In cancelled");
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint("Google ID Token is null");
        return false;
      }

      final response = await ref
          .read(supAuthProv)
          .signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session != null) {
        debugPrint('Google Sign-In successful');
        return true;
      } else {
        debugPrint('Google Sign-In failed: No session created');
        return false;
      }
    } catch (e) {
      debugPrint("Google Sign-In error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(supAuthProv).signOut();
      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}