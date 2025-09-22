import 'package:flutter/material.dart';

class ResettingInteractiveViewer extends StatefulWidget {
  final Widget child;
  final EdgeInsets boundaryMargin;
  final double minScale;
  final double maxScale;

  const ResettingInteractiveViewer({
    Key? key,
    required this.child,
    this.boundaryMargin = const EdgeInsets.all(20),
    this.minScale = 1.0,
    this.maxScale = 4.0,
  }) : super(key: key);

  @override
  State<ResettingInteractiveViewer> createState() => _ResettingInteractiveViewerState();
}

class _ResettingInteractiveViewerState extends State<ResettingInteractiveViewer> with SingleTickerProviderStateMixin {
  late final TransformationController _controller;
  late final AnimationController _animationController;
  Matrix4? _animationStart;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _animationController.addListener(() {
      final start = _animationStart ?? Matrix4.identity();
      final tween = Matrix4Tween(begin: start, end: Matrix4.identity());
      _controller.value = tween.transform(_animationController.value);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _resetWithAnimation() {
    _animationStart = _controller.value.clone();
    _animationController
      ..stop()
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      boundaryMargin: widget.boundaryMargin,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      onInteractionEnd: (_) {
        if (mounted) {
          _resetWithAnimation();
        }
      },
      child: widget.child,
    );
  }
}