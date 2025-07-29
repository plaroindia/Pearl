import 'package:flutter/material.dart';

class EventPageShimmer extends StatelessWidget {
  const EventPageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}