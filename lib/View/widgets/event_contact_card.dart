import 'package:flutter/material.dart';
import '../../Model/event.dart';

class EventContactCard extends StatelessWidget {
  final Event event;
  const EventContactCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.contact_mail),
        title: Text(event.organizationName),
        subtitle: const Text("For queries, contact organizer"),
      ),
    );
  }
}