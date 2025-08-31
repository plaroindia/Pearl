import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'widgets/event_category_row.dart';
import 'widgets/event_page_shimmer.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'package:plaro_3/ViewModel/event_provider.dart';
import 'widgets/plaro_app_bar.dart';
import 'dart:async';
import 'create_events_page.dart';

class AllEventsPage extends HookConsumerWidget {
  const AllEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventFeedProvider);
    // Use ref.watch on the notifier to ensure rebuilds when filtered lists change
    final notifier = ref.watch(eventFeedProvider.notifier);

    final searchQuery = state.searchQuery;
    final categories = [
      {'title': 'Trending', 'events': notifier.filteredTrendingEvents},
      {'title': 'Hackathons', 'events': notifier.filteredUpcomingHackathons},
      {'title': 'Competitions', 'events': notifier.filteredTrendingCompetitions},
    ];

    final hasResults = categories.any((cat) => (cat['events'] as List).isNotEmpty);

    return Scaffold(
      appBar: PlaroAppBar(
        // This search and filter logic is already wired to the provider.
        // As the user types or applies filters, the event list updates reactively.
        onSearch: notifier.setSearchQuery,
        onFilter: () async {
          final selectedFilters = await showModalBottomSheet(
            context: context,
            builder: (_) => FilterBottomSheet(initialFilters: state.filterOptions),
          );
          if (selectedFilters != null) {
            notifier.applyFilters(selectedFilters);
          }
        },
      ),
      body: state.isLoading
          ? const EventPageShimmer()
          : state.error != null
          ? Center(child: Text("Error: ${state.error}"))
          : RefreshIndicator(
        onRefresh: notifier.loadEvents,
        child: hasResults
            ? _AnimatedCategoryList(categories: categories, searchQuery: searchQuery)
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No events found',
                style: TextStyle(fontSize: 20, color: Colors.grey[700], fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters.',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventScreen(),
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

    );
  }
}

class _AnimatedCategoryList extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final String searchQuery;
  const _AnimatedCategoryList({required this.categories, required this.searchQuery});

  @override
  State<_AnimatedCategoryList> createState() => _AnimatedCategoryListState();
}

class _AnimatedCategoryListState extends State<_AnimatedCategoryList> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.categories.length, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });
    _fadeAnimations = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: Curves.easeIn)))
        .toList();
    _slideAnimations = _controllers
        .map((c) => Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _runStaggeredAnimations();
  }

  Future<void> _runStaggeredAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.categories.length,
      itemBuilder: (context, i) {
        final cat = widget.categories[i];
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) => Opacity(
            opacity: _fadeAnimations[i].value,
            child: SlideTransition(
              position: _slideAnimations[i],
              child: child,
            ),
          ),
          child: EventCategoryRow(title: cat['title'], events: cat['events'], searchQuery: widget.searchQuery),
        );
      },
    );

  }
}