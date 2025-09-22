import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Model/toast.dart';
import 'toast_card.dart';

class ToastDetailViewer extends ConsumerWidget {
  final Toast_feed toast;

  const ToastDetailViewer({super.key, required this.toast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: ToastCard(
            toast: toast,
            onTap: () {},
            onUserInfo: () {},
          ),
        ),
      ),
    );
  }
}


