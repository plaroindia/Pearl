import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../ViewModel/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false;

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider).logout();

      // Show success message
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white54,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "PLARO",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 20.0,
                letterSpacing: 0.0,
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Implement search functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search functionality coming soon')),
                );
              },
              icon: const Icon(Icons.search),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black87,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    authState.when(
                      data: (session) {
                        return Text(
                          session?.user?.email ?? 'No user',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      loading: () => const Text(
                        'Loading...',
                        style: TextStyle(color: Colors.grey),
                      ),
                      error: (error, stack) => const Text(
                        'Error loading user',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Items
              ListTile(
                leading: const Icon(Icons.home, color: Colors.grey),
                title: const Text(
                  'Home',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text(
                  'Settings',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to settings
                },
              ),

              const Divider(color: Colors.grey),

              // Sign Out
              ListTile(
                leading: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                )
                    : const Icon(Icons.logout, color: Colors.grey),
                title: Text(
                  _isLoading ? 'Signing out...' : 'Sign Out',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: _isLoading ? null : _handleSignOut,
              ),
            ],
          ),
        ),
      ),
      body: authState.when(
        data: (session) {
          if (session == null) {
            // User is not authenticated, this shouldn't happen if routing is correct
            return const Center(
              child: Text(
                'Please log in to continue',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to PLARO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hello, ${session.user?.email}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 32),
                // Add your main content here
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Your main app content goes here',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}