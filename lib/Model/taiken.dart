class Taiken {
  final String taikenId;
  final String creatorId;
  final String title;
  final String description;
  final String domain;
  final String difficulty;
  final String introScript;
  final String outroSuccessScript;
  final String outroFailureScript;
  final String? thumbnailUrl;
  final int totalStages;
  final int totalQuestions;
  final int passThreshold;
  final int playCount;
  final double averageRating;
  final int ratingCount;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  Taiken({
    required this.taikenId,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.domain,
    required this.difficulty,
    required this.introScript,
    required this.outroSuccessScript,
    required this.outroFailureScript,
    this.thumbnailUrl,
    required this.totalStages,
    required this.totalQuestions,
    this.passThreshold = 50,
    this.playCount = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.isPublished = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Taiken.fromJson(Map<String, dynamic> json) {
    return Taiken(
      taikenId: json['taiken_id'],
      creatorId: json['creator_id'],
      title: json['title'],
      description: json['description'] ?? '',
      domain: json['domain'],
      difficulty: json['difficulty'],
      introScript: json['intro_script'],
      outroSuccessScript: json['outro_success_script'],
      outroFailureScript: json['outro_failure_script'],
      thumbnailUrl: json['thumbnail_url'],
      totalStages: json['total_stages'],
      totalQuestions: json['total_questions'],
      passThreshold: json['pass_threshold'] ?? 50,
      playCount: json['play_count'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      isPublished: json['is_published'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taiken_id': taikenId,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'domain': domain,
      'difficulty': difficulty,
      'intro_script': introScript,
      'outro_success_script': outroSuccessScript,
      'outro_failure_script': outroFailureScript,
      'thumbnail_url': thumbnailUrl,
      'total_stages': totalStages,
      'total_questions': totalQuestions,
      'pass_threshold': passThreshold,
      'play_count': playCount,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class TaikenStage {
  final String stageId;
  final String taikenId;
  final int stageOrder;
  final String stageTitle;
  final String? sceneImageUrl;
  final DateTime createdAt;

  TaikenStage({
    required this.stageId,
    required this.taikenId,
    required this.stageOrder,
    required this.stageTitle,
    this.sceneImageUrl,
    required this.createdAt,
  });

  factory TaikenStage.fromJson(Map<String, dynamic> json) {
    return TaikenStage(
      stageId: json['stage_id'],
      taikenId: json['taiken_id'],
      stageOrder: json['stage_order'],
      stageTitle: json['stage_title'],
      sceneImageUrl: json['scene_image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage_id': stageId,
      'taiken_id': taikenId,
      'stage_order': stageOrder,
      'stage_title': stageTitle,
      'scene_image_url': sceneImageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TaikenCharacter {
  final String characterId;
  final String taikenId;
  final String characterName;
  final String? characterImageUrl;
  final String? characterDescription;
  final int displayOrder;
  final DateTime createdAt;

  TaikenCharacter({
    required this.characterId,
    required this.taikenId,
    required this.characterName,
    this.characterImageUrl,
    this.characterDescription,
    required this.displayOrder,
    required this.createdAt,
  });

  factory TaikenCharacter.fromJson(Map<String, dynamic> json) {
    return TaikenCharacter(
      characterId: json['character_id'],
      taikenId: json['taiken_id'],
      characterName: json['character_name'],
      characterImageUrl: json['character_image_url'],
      characterDescription: json['character_description'],
      displayOrder: json['display_order'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'character_id': characterId,
      'taiken_id': taikenId,
      'character_name': characterName,
      'character_image_url': characterImageUrl,
      'character_description': characterDescription,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TaikenDialogue {
  final String dialogueId;
  final String stageId;
  final String? characterId;
  final String dialogueText;
  final int dialogueOrder;
  final DateTime createdAt;

  TaikenDialogue({
    required this.dialogueId,
    required this.stageId,
    this.characterId,
    required this.dialogueText,
    required this.dialogueOrder,
    required this.createdAt,
  });

  factory TaikenDialogue.fromJson(Map<String, dynamic> json) {
    return TaikenDialogue(
      dialogueId: json['dialogue_id'],
      stageId: json['stage_id'],
      characterId: json['character_id'],
      dialogueText: json['dialogue_text'],
      dialogueOrder: json['dialogue_order'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dialogue_id': dialogueId,
      'stage_id': stageId,
      'character_id': characterId,
      'dialogue_text': dialogueText,
      'dialogue_order': dialogueOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TaikenQuestion {
  final String questionId;
  final String stageId;
  final String questionText;
  final String questionType;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;
  final int questionOrder;
  final DateTime createdAt;

  TaikenQuestion({
    required this.questionId,
    required this.stageId,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
    required this.questionOrder,
    required this.createdAt,
  });

  factory TaikenQuestion.fromJson(Map<String, dynamic> json) {
    return TaikenQuestion(
      questionId: json['question_id'],
      stageId: json['stage_id'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correct_option_index'],
      explanation: json['explanation'],
      questionOrder: json['question_order'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'stage_id': stageId,
      'question_text': questionText,
      'question_type': questionType,
      'options': options,
      'correct_option_index': correctOptionIndex,
      'explanation': explanation,
      'question_order': questionOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TaikenProgress {
  final String progressId;
  final String userId;
  final String taikenId;
  final int currentStageOrder;
  final int questionsAnswered;
  final int correctAnswers;
  final int wrongAnswers;
  final String status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaikenProgress({
    required this.progressId,
    required this.userId,
    required this.taikenId,
    required this.currentStageOrder,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    required this.status,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  double get accuracyPercentage {
    if (questionsAnswered == 0) return 0.0;
    return (correctAnswers / questionsAnswered) * 100;
  }

  TaikenProgress copyWith({
    String? progressId,
    String? userId,
    String? taikenId,
    int? currentStageOrder,
    int? questionsAnswered,
    int? correctAnswers,
    int? wrongAnswers,
    String? status,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaikenProgress(
      progressId: progressId ?? this.progressId,
      userId: userId ?? this.userId,
      taikenId: taikenId ?? this.taikenId,
      currentStageOrder: currentStageOrder ?? this.currentStageOrder,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaikenProgress.fromJson(Map<String, dynamic> json) {
    return TaikenProgress(
      progressId: json['progress_id'],
      userId: json['user_id'],
      taikenId: json['taiken_id'],
      currentStageOrder: json['current_stage_order'],
      questionsAnswered: json['questions_answered'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      wrongAnswers: json['wrong_answers'] ?? 0,
      status: json['status'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progress_id': progressId,
      'user_id': userId,
      'taiken_id': taikenId,
      'current_stage_order': currentStageOrder,
      'questions_answered': questionsAnswered,
      'correct_answers': correctAnswers,
      'wrong_answers': wrongAnswers,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class TaikenRating {
  final String ratingId;
  final String taikenId;
  final String userId;
  final int rating;
  final String? review;
  final DateTime createdAt;

  TaikenRating({
    required this.ratingId,
    required this.taikenId,
    required this.userId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory TaikenRating.fromJson(Map<String, dynamic> json) {
    return TaikenRating(
      ratingId: json['rating_id'],
      taikenId: json['taiken_id'],
      userId: json['user_id'],
      rating: json['rating'],
      review: json['review'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating_id': ratingId,
      'taiken_id': taikenId,
      'user_id': userId,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
    };
  }
}