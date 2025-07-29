import 'package:flutter/material.dart';
import '../../Model/event.dart';
import 'event_card.dart';

class EventCategoryRow extends StatelessWidget {
  final String title;
  final List<Event> events;
  final String searchQuery;

  const EventCategoryRow({super.key, required this.title, required this.events, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => SizedBox(width: 220, child: EventCard(event: events[i], searchQuery: searchQuery)),
          ),
        ),
      ],
    );
  }
}