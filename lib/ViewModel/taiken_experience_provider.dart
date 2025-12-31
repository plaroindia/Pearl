import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/taiken.dart';

class TaikenExperienceState {
  final Taiken? taiken;
  final List<TaikenStage> stages;
  final List<TaikenCharacter> characters;
  final Map<String, List<TaikenDialogue>> dialoguesByStage;
  final Map<String, List<TaikenQuestion>> questionsByStage;
  final TaikenProgress? progress;
  final int currentStageIndex;
  final int currentDialogueIndex;
  final int currentQuestionIndex;
  final bool isLoading;
  final String? error;
  final bool showingIntro;
  final bool showingOutro;
  final Map<String, int?> userAnswers;
  final int? userRating;

  TaikenExperienceState({
    this.taiken,
    this.stages = const [],
    this.characters = const [],
    this.dialoguesByStage = const {},
    this.questionsByStage = const {},
    this.progress,
    this.currentStageIndex = 0,
    this.currentDialogueIndex = 0,
    this.currentQuestionIndex = 0,
    this.isLoading = false,
    this.error,
    this.showingIntro = true,
    this.showingOutro = false,
    this.userAnswers = const {},
    this.userRating,
  });

  TaikenExperienceState copyWith({
    Taiken? taiken,
    List<TaikenStage>? stages,
    List<TaikenCharacter>? characters,
    Map<String, List<TaikenDialogue>>? dialoguesByStage,
    Map<String, List<TaikenQuestion>>? questionsByStage,
    TaikenProgress? progress,
    int? currentStageIndex,
    int? currentDialogueIndex,
    int? currentQuestionIndex,
    bool? isLoading,
    String? error,
    bool? showingIntro,
    bool? showingOutro,
    Map<String, int?>? userAnswers,
    int? userRating,
  }) {
    return TaikenExperienceState(
      taiken: taiken ?? this.taiken,
      stages: stages ?? this.stages,
      characters: characters ?? this.characters,
      dialoguesByStage: dialoguesByStage ?? this.dialoguesByStage,
      questionsByStage: questionsByStage ?? this.questionsByStage,
      progress: progress ?? this.progress,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      currentDialogueIndex: currentDialogueIndex ?? this.currentDialogueIndex,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      showingIntro: showingIntro ?? this.showingIntro,
      showingOutro: showingOutro ?? this.showingOutro,
      userAnswers: userAnswers ?? this.userAnswers,
      userRating: userRating ?? this.userRating,
    );
  }

  TaikenStage? get currentStage =>
      currentStageIndex < stages.length ? stages[currentStageIndex] : null;

  List<TaikenDialogue> get currentDialogues =>
      currentStage != null ? dialoguesByStage[currentStage!.stageId] ?? [] : [];

  List<TaikenQuestion> get currentQuestions =>
      currentStage != null ? questionsByStage[currentStage!.stageId] ?? [] : [];

  bool get hasMoreDialogues => currentDialogueIndex < currentDialogues.length;
  bool get hasMoreQuestions => currentQuestionIndex < currentQuestions.length;
  bool get hasMoreStages => currentStageIndex < stages.length - 1;
}

class TaikenExperienceNotifier extends StateNotifier<TaikenExperienceState> {
  TaikenExperienceNotifier(this.taikenId) : super(TaikenExperienceState());

  final String taikenId;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> loadTaiken() async {
    state = state.copyWith(isLoading: true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Load taiken metadata
      final taikenResponse = await _supabase
          .from('taikens')
          .select()
          .eq('taiken_id', taikenId)
          .single();
      final taiken = Taiken.fromJson(taikenResponse);

      // Load stages
      final stagesResponse = await _supabase
          .from('taiken_stages')
          .select()
          .eq('taiken_id', taikenId)
          .order('stage_order');
      final stages = (stagesResponse as List)
          .map((json) => TaikenStage.fromJson(json))
          .toList();

      // Load characters
      final charactersResponse = await _supabase
          .from('taiken_characters')
          .select()
          .eq('taiken_id', taikenId)
          .order('display_order');
      final characters = (charactersResponse as List)
          .map((json) => TaikenCharacter.fromJson(json))
          .toList();

      // Load dialogues per stage
      final Map<String, List<TaikenDialogue>> dialoguesByStage = {};
      for (final stage in stages) {
        final dialoguesResponse = await _supabase
            .from('taiken_dialogues')
            .select()
            .eq('stage_id', stage.stageId)
            .order('dialogue_order');
        dialoguesByStage[stage.stageId] = (dialoguesResponse as List)
            .map((json) => TaikenDialogue.fromJson(json))
            .toList();
      }

      // Load questions per stage
      final Map<String, List<TaikenQuestion>> questionsByStage = {};
      for (final stage in stages) {
        final questionsResponse = await _supabase
            .from('taiken_questions')
            .select()
            .eq('stage_id', stage.stageId)
            .order('question_order');
        questionsByStage[stage.stageId] = (questionsResponse as List)
            .map((json) => TaikenQuestion.fromJson(json))
            .toList();
      }

      // Try to load existing progress
      TaikenProgress? progress;
      try {
        // Use fresh query (no caching)
        final progressResponse = await _supabase
            .from('taiken_progress')
            .select()
            .eq('user_id', userId)
            .eq('taiken_id', taikenId)
            .order('created_at', ascending: false)  // Get most recent
            .limit(1)
            .single();
        progress = TaikenProgress.fromJson(progressResponse);
      } catch (e) {
        // No progress found - create fresh one
        final newProgressData = {
          'user_id': userId,
          'taiken_id': taikenId,
          'current_stage_order': 1,
          'questions_answered': 0,
          'correct_answers': 0,
          'wrong_answers': 0,
          'status': 'in_progress',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        final createdProgress = await _supabase
            .from('taiken_progress')
            .insert(newProgressData)
            .select()
            .single();
        progress = TaikenProgress.fromJson(createdProgress);
      }

      // Load existing rating
      int? existingRating;
      try {
        final ratingResponse = await _supabase
            .from('taiken_ratings')
            .select()
            .eq('user_id', userId)
            .eq('taiken_id', taikenId)
            .single();
        existingRating = ratingResponse['rating'] as int?;
      } catch (e) {
        // No rating yet
      }

      // Determine initial UI state
      final showingIntro = progress.currentStageOrder == 1 &&
          progress.questionsAnswered == 0;
      final currentStageIndex = progress.currentStageOrder - 1;

      state = state.copyWith(
        taiken: taiken,
        stages: stages,
        characters: characters,
        dialoguesByStage: dialoguesByStage,
        questionsByStage: questionsByStage,
        progress: progress,
        currentStageIndex: currentStageIndex,
        currentDialogueIndex: 0,
        currentQuestionIndex: 0,
        showingIntro: showingIntro,
        showingOutro: false,
        isLoading: false,
        error: null,
        userRating: existingRating,
        userAnswers: {},  // Always start fresh
      );

      // Increment play count (only once per load, not on retry)
      if (progress.questionsAnswered == 0) {
        await _supabase.rpc('increment_play_count', params: {'taiken_id': taikenId});
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load Taiken: $e',
      );
    }
  }

  void startExperience() {
    state = state.copyWith(showingIntro: false);
  }

 void advanceDialogue() {
    if (state.hasMoreDialogues) {
      // Still have dialogues to show - increment index
      state = state.copyWith(
        currentDialogueIndex: state.currentDialogueIndex + 1,
      );
    } else {
      // All dialogues shown - transition to questions
      // DON'T reset currentDialogueIndex to 0, just mark questions as active
      state = state.copyWith(
        currentQuestionIndex: 0,
      );
    }
  }

Future<void> submitAnswer(String questionId, int selectedIndex) async {
  try {
    final question = state.currentQuestions[state.currentQuestionIndex];
    final isCorrect = selectedIndex == question.correctOptionIndex;

    final updatedAnswers = Map<String, int?>.from(state.userAnswers);
    updatedAnswers[questionId] = selectedIndex;

    final newCorrectAnswers = state.progress!.correctAnswers + (isCorrect ? 1 : 0);
    final newWrongAnswers = state.progress!.wrongAnswers + (isCorrect ? 0 : 1);
    final newQuestionsAnswered = state.progress!.questionsAnswered + 1;

    final totalQuestions = state.taiken!.totalQuestions;
    final passThreshold = state.taiken!.passThreshold;

    // Calculate current accuracy
    final currentAccuracy = (newCorrectAnswers / newQuestionsAnswered) * 100;

    // Calculate if it's mathematically impossible to pass
    final questionsRemaining = totalQuestions - newQuestionsAnswered;
    final maxPossibleCorrect = newCorrectAnswers + questionsRemaining;
    final maxPossibleAccuracy = (maxPossibleCorrect / totalQuestions) * 100;

    String newStatus = state.progress!.status;
    DateTime? completedAt;

    // Check if user has mathematically failed (can't reach pass threshold even if they get all remaining questions right)
    if (maxPossibleAccuracy < passThreshold) {
      newStatus = 'failed';
      completedAt = DateTime.now();
    }
    // Check if all questions are answered
    else if (newQuestionsAnswered >= totalQuestions) {
      final finalAccuracy = (newCorrectAnswers / totalQuestions) * 100;
      if (finalAccuracy >= passThreshold) {
        newStatus = 'completed';
      } else {
        newStatus = 'failed';
      }
      completedAt = DateTime.now();
    }

    await _supabase
        .from('taiken_progress')
        .update({
      'questions_answered': newQuestionsAnswered,
      'correct_answers': newCorrectAnswers,
      'wrong_answers': newWrongAnswers,
      'status': newStatus,
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('progress_id', state.progress!.progressId);

    final updatedProgress = state.progress!.copyWith(
      questionsAnswered: newQuestionsAnswered,
      correctAnswers: newCorrectAnswers,
      wrongAnswers: newWrongAnswers,
      status: newStatus,
      completedAt: completedAt,
    );

    state = state.copyWith(
      progress: updatedProgress,
      userAnswers: updatedAnswers,
    );

    if (newStatus == 'completed' || newStatus == 'failed') {
      state = state.copyWith(showingOutro: true);
    } else {
      advanceToNextQuestion();
    }
  } catch (e) {
    state = state.copyWith(error: 'Failed to submit answer: $e');
   }
  }

  void advanceToNextQuestion() {
    if (state.currentQuestionIndex < state.currentQuestions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    } else if (state.hasMoreStages) {
      advanceToNextStage();
    } else {
      state = state.copyWith(showingOutro: true);
    }
  }

Future<void> advanceToNextStage() async {
  final nextStageIndex = state.currentStageIndex + 1;
  final nextStageOrder = nextStageIndex + 1;

  await _supabase
      .from('taiken_progress')
      .update({
    'current_stage_order': nextStageOrder,
    'updated_at': DateTime.now().toIso8601String(),
  })
      .eq('progress_id', state.progress!.progressId);

  state = state.copyWith(
    currentStageIndex: nextStageIndex,
    currentDialogueIndex: 0,  // This already resets for new stage
    currentQuestionIndex: 0,
  );
}
 Future<void> rateTaiken(int rating, String? review) async {
  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Use upsert to insert or update the rating
    await _supabase.from('taiken_ratings').upsert({
      'taiken_id': taikenId,
      'user_id': userId,
      'rating': rating,
      'review': review,
    }, onConflict: 'taiken_id,user_id'); // Specify the conflict columns

  } catch (e) {
    state = state.copyWith(error: 'Failed to submit rating: $e');
  }
}

  Future<void> resetAndRestart() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // STEP 1: Delete ALL existing progress records for this user+taiken
      // Use explicit filter and await completion
      await _supabase
          .from('taiken_progress')
          .delete()
          .eq('user_id', userId)
          .eq('taiken_id', taikenId);
      
      // STEP 2: Small delay to ensure database propagation (if using replicas)
      await Future.delayed(const Duration(milliseconds: 100));

      // STEP 3: Reset provider state to fresh initial state
      state = TaikenExperienceState(
        showingIntro: true,  // Force show intro screen
        showingOutro: false,
        currentStageIndex: 0,
        currentDialogueIndex: 0,
        currentQuestionIndex: 0,
        userAnswers: {},  // Clear all answers
      );

      // STEP 4: Reload taiken data from scratch (will create new progress record)
      await loadTaiken();
      
      // Verify we're starting fresh
      if (state.progress?.currentStageOrder != 1 || 
          state.progress?.questionsAnswered != 0) {
        throw Exception('Failed to reset progress properly');
      }
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to reset progress: $e');
      rethrow;
    }
  }

  void reset() {
    state = TaikenExperienceState();
  }
}

final taikenExperienceProvider = StateNotifierProvider.family<
    TaikenExperienceNotifier,
    TaikenExperienceState,
    String>((ref, taikenId) {
  return TaikenExperienceNotifier(taikenId);
});