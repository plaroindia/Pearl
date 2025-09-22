import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Model/toast.dart';
import 'toast_card.dart';

class ProfileToastLightbox extends ConsumerStatefulWidget {
  final List<Toast_feed> toasts;
  final int initialIndex;

  const ProfileToastLightbox({super.key, required this.toasts, required this.initialIndex});

  @override
  ConsumerState<ProfileToastLightbox> createState() => _ProfileToastLightboxState();
}

class _ProfileToastLightboxState extends ConsumerState<ProfileToastLightbox> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1}/${widget.toasts.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemCount: widget.toasts.length,
        itemBuilder: (context, index) {
          final toast = widget.toasts[index];
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ToastCard(
                toast: toast,
                onTap: () {},
                onUserInfo: () {},
              ),
            ),
          );
        },
      ),
    );
  }
}


