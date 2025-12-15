import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'package:flutter/animation.dart';
import 'dart:async';
import 'home_page.dart';
import 'navipg.dart';


class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({super.key});

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage> with TickerProviderStateMixin {
  bool _isInitializing = true;

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

    // Supabase is now initialized in main(), wait a bit then navigate
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _completeAnimationsAndNavigate();
      }
    });
  }

  Future<void> _startAnimations() async {
    // Start zoom animation
    await _zoomController.forward();

    // Loop the zoom animation while initializing
    if (_isInitializing) {
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

  // Supabase initialization moved to main()

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
            ]
          ],
        ),
      ),
    );
  }
}