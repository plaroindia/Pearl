import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'package:flutter/animation.dart';
import 'dart:async';
import 'home_page.dart';
import 'navipg.dart';
import '../constants/auth_keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({super.key});

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage> with TickerProviderStateMixin {
  bool _isInitializing = true;
  bool _initializationFailed = false;
  String? _errorMessage;

  late final AnimationController _zoomController;
  late final Animation<double> _zoomAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create animations
    _zoomAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    // Start animation sequence
    _startAnimations();

    // Initialize Supabase
    _initializeSupabase();
  }

  Future<void> _startAnimations() async {
    // Start zoom animation
    await _zoomController.forward();

    // Loop the zoom animation while initializing
    if (_isInitializing && !_initializationFailed) {
      _zoomController.repeat(reverse: true);
    }
  }

  Future<void> _completeAnimationsAndNavigate() async {
    // Stop any looping animation
    _zoomController.stop();

    // Start fade animation
    await _fadeController.forward();

    // Navigate based on auth state
    if (mounted) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => navCard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeSupabase() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
        ),
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });

        // Complete animations and navigate
        await _completeAnimationsAndNavigate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationFailed = true;
          _errorMessage = e.toString();
        });

        // If initialization fails, still complete animations and go to login
        await _completeAnimationsAndNavigate();
      }
    }
  }

  void _retryInitialization() {
    setState(() {
      _isInitializing = true;
      _initializationFailed = false;
      _errorMessage = null;
    });
    _initializeSupabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: _isInitializing
                    ? []
                    : [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _zoomAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/plaro_logo.png',
                        height: 140,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        ' Plaro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Status indicators
            if (_isInitializing) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
              const SizedBox(height: 16),
              const Text(
                'Initializing...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ] else if (_initializationFailed) ...[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _retryInitialization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}