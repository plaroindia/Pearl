// courses_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'widgets/course_playlist_card.dart';
import 'widgets/course_detail_page.dart';
import 'widgets/course_page_shimmer.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'package:plaro_3/ViewModel/course_provider.dart';
import 'widgets/plaro_app_bar.dart';

class CoursesPage extends HookConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseFeedProvider);
    final notifier = ref.watch(courseFeedProvider.notifier);

    final searchQuery = state.searchQuery;
    final categories = [
      {'title': 'Popular Courses', 'courses': notifier.filteredPopularCourses},
      {'title': 'Programming', 'courses': notifier.filteredProgrammingCourses},
      {'title': 'Design', 'courses': notifier.filteredDesignCourses},
      {'title': 'Business', 'courses': notifier.filteredBusinessCourses},
      {'title': 'Data Science', 'courses': notifier.filteredDataScienceCourses},
    ];

    final hasResults = categories.any((cat) => (cat['courses'] as List).isNotEmpty);

    return Scaffold(
      appBar: PlaroAppBar(
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
          ? const CoursePageShimmer()
          : state.error != null
          ? Center(child: Text("Error: ${state.error}"))
          : RefreshIndicator(
        onRefresh: notifier.loadCourses,
        child: hasResults
            ? _AnimatedCourseGrid(categories: categories, searchQuery: searchQuery)
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No courses found',
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
    );
  }
}

class _AnimatedCourseGrid extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final String searchQuery;

  const _AnimatedCourseGrid({required this.categories, required this.searchQuery});

  @override
  State<_AnimatedCourseGrid> createState() => _AnimatedCourseGridState();
}

class _AnimatedCourseGridState extends State<_AnimatedCourseGrid> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.categories.length, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });
    _fadeAnimations = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: Curves.easeIn)))
        .toList();
    _slideAnimations = _controllers
        .map((c) => Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _runStaggeredAnimations();
  }

  Future<void> _runStaggeredAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.categories.length,
      itemBuilder: (context, i) {
        final category = widget.categories[i];
        final courses = category['courses'] as List;

        if (courses.isEmpty) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) => Opacity(
            opacity: _fadeAnimations[i].value,
            child: SlideTransition(
              position: _slideAnimations[i],
              child: child,
            ),
          ),
          child: _CategorySection(
            title: category['title'],
            courses: courses,
            searchQuery: widget.searchQuery,
          ),
        );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List courses;
  final String searchQuery;

  const _CategorySection({
    required this.title,
    required this.courses,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to see all courses in this category
                },
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CoursePlaylistCard(
                  course: course,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailPage(course: course),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}


