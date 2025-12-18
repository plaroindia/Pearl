import 'package:flutter/material.dart';
import '../../Model/event.dart';
import '../event_detail_page.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final String searchQuery;
  const EventCard({super.key, required this.event, this.searchQuery = ''});

  TextSpan _highlightText(String text, String query, Color color) {
    if (query.isEmpty) return TextSpan(text: text, style: TextStyle(color: color));
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final start = lower.indexOf(q);
    if (start == -1) return TextSpan(text: text, style: TextStyle(color: color));
    final end = start + q.length;
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, start), style: TextStyle(color: color)),
        TextSpan(text: text.substring(start, end), style: TextStyle(backgroundColor: Color(0xFFFFF59D), fontWeight: FontWeight.bold, color: color)),
        TextSpan(text: text.substring(end), style: TextStyle(color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 0, maxHeight: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: _highlightText(event.title, searchQuery, colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.fade,

                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.organizationName,
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${event.startDate.toLocal().toString().split(' ')[0]}",
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            physics: const ClampingScrollPhysics(),
                            child: Wrap(
                              spacing: 4,
                              children: event.tags
                                  .take(3)
                                  .map((tag) => Chip(
                                label: Text(
                                  tag,
                                  style: TextStyle(fontSize: 10, color: colorScheme.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}