import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

final supAuthProv = Provider((ref) => Supabase.instance.client.auth);

final authStateProvider = StreamProvider((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
        (event) => event.session,
  );
});

final authControllerProvider = Provider((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref ref;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Use your WEB client ID here (not Android client ID)
    serverClientId: AppConfig.googleSignInServerClientId,
  );

  AuthController(this.ref);

  /// 📹 Email/Password Login
  Future<bool> login({required String email, required String password}) async {
    try {
      final response = await ref
          .read(supAuthProv)
          .signInWithPassword(email: email, password: password);

      return response.session != null;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// 📹 Signup
  Future<bool> logUp({required String email, required String password}) async {
    try {
      final response = await ref
          .read(supAuthProv)
          .signUp(email: email, password: password);

      debugPrint('SignUp response: ${response.user?.email}');

      if (response.user != null) {
        if (response.session != null) {
          debugPrint('SignUp successful with immediate session');
          return true;
        } else {
          debugPrint('SignUp successful - email confirmation required');
          return true;
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

  /// 📹 Google Sign-In
  Future<bool> googleSignIn() async {
    try {
      // Clear any existing sign-in state
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Google Sign-In cancelled by user");
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      debugPrint("Google ID Token: ${idToken != null ? 'Present' : 'Null'}");
      debugPrint("Google Access Token: ${accessToken != null ? 'Present' : 'Null'}");

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
        debugPrint('User: ${response.user?.email}');
        return true;
      } else {
        debugPrint('Google Sign-In failed: No session created');
        return false;
      }
    } catch (e) {
      debugPrint("Google Sign-In error: $e");
      // Print more detailed error information
      if (e.toString().contains('network')) {
        debugPrint("Network error - check internet connection");
      } else if (e.toString().contains('configuration')) {
        debugPrint("Configuration error - check OAuth setup");
      }
      return false;
    }
  }

  /// 📹 Logout with Google disconnect
  Future<void> logout() async {
    try {
      await ref.read(supAuthProv).signOut();
      debugPrint('User logged out from Supabase');

      // Also disconnect from Google to clear session cache
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      debugPrint('Google session disconnected');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}