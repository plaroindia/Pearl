import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/taiken.dart';

class TaikenListState {
  final List<Taiken> taikens;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final String? searchQuery;
  final String? filterDomain;
  final String? filterDifficulty;

  TaikenListState({
    this.taikens = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.searchQuery,
    this.filterDomain,
    this.filterDifficulty,
  });

  TaikenListState copyWith({
    List<Taiken>? taikens,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    String? searchQuery,
    String? filterDomain,
    String? filterDifficulty,
  }) {
    return TaikenListState(
      taikens: taikens ?? this.taikens,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filterDomain: filterDomain ?? this.filterDomain,
      filterDifficulty: filterDifficulty ?? this.filterDifficulty,
    );
  }
}

class TaikenListNotifier extends StateNotifier<TaikenListState> {
  TaikenListNotifier() : super(TaikenListState());

  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 10;

  Future<void> loadTaikens({bool refresh = false}) async {
    if (refresh) {
      state = TaikenListState(isLoading: true);
    } else if (state.isLoading || state.isLoadingMore) {
      return;
    }

    state = state.copyWith(
      isLoading: refresh,
      isLoadingMore: !refresh && state.taikens.isNotEmpty,
    );

    try {
      dynamic query = _supabase.from('taikens').select();
      
      query = query.eq('is_published', true);
      
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        query = query.ilike('title', '%${state.searchQuery}%');
      }
      if (state.filterDomain != null) {
        query = query.eq('domain', state.filterDomain!);
      }
      if (state.filterDifficulty != null) {
        query = query.eq('difficulty', state.filterDifficulty!);
      }
      
      query = query
          .order('created_at', ascending: false)
          .range(
            refresh ? 0 : state.taikens.length,
            refresh ? _pageSize - 1 : state.taikens.length + _pageSize - 1,
          );

      final response = await query;
      final List<Taiken> newTaikens = (response as List)
          .map((json) => Taiken.fromJson(json))
          .toList();

      state = state.copyWith(
        taikens: refresh ? newTaikens : [...state.taikens, ...newTaikens],
        isLoading: false,
        isLoadingMore: false,
        hasMore: newTaikens.length == _pageSize,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Failed to load Taikens: $e',
      );
    }
  }

  Future<void> searchTaikens(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadTaikens(refresh: true);
  }

  Future<void> filterByDomain(String? domain) async {
    state = state.copyWith(filterDomain: domain);
    await loadTaikens(refresh: true);
  }

  Future<void> filterByDifficulty(String? difficulty) async {
    state = state.copyWith(filterDifficulty: difficulty);
    await loadTaikens(refresh: true);
  }

  void clearFilters() {
    state = TaikenListState();
    loadTaikens(refresh: true);
  }
}

final taikenListProvider = StateNotifierProvider<TaikenListNotifier, TaikenListState>((ref) {
  return TaikenListNotifier();
});