import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'river_prov.dart';

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
      return false; // Make sure to return false on error
    }
  }

  Future<bool> signin({
    required String email,
    required String password,
  })async{

  }
}