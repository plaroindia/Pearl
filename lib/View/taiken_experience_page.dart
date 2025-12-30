// lib/View/taiken_experience_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ViewModel/taiken_experience_provider.dart';
import '../Model/taiken.dart';

class TaikenExperiencePage extends ConsumerStatefulWidget {
  final String taikenId;

  const TaikenExperiencePage({
    super.key,
    required this.taikenId,
  });

  @override
  ConsumerState<TaikenExperiencePage> createState() => _TaikenExperiencePageState();
}

class _TaikenExperiencePageState extends ConsumerState<TaikenExperiencePage> {
  int? _selectedAnswerIndex;
  bool _showExplanation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taikenExperienceProvider(widget.taikenId).notifier).loadTaiken();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taikenExperienceProvider(widget.taikenId));

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.taiken == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text('Taiken not found')),
      );
    }

    // Show intro screen
    if (state.showingIntro) {
      return _buildIntroScreen(state);
    }

    // Show outro screen
    if (state.showingOutro) {
      return _buildOutroScreen(state);
    }

    // Show main experience
    return _buildExperienceScreen(state);
  }

  Widget _buildIntroScreen(TaikenExperienceState state) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.taiken!.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    state.taiken!.thumbnailUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Text(
                state.taiken!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.taiken!.introScript,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                Icons.layers,
                '${state.taiken!.totalStages} Stages',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.quiz,
                '${state.taiken!.totalQuestions} Questions',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.check_circle,
                'Pass: ${state.taiken!.passThreshold}% correct',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(taikenExperienceProvider(widget.taikenId).notifier)
                        .startExperience();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start Experience',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildOutroScreen(TaikenExperienceState state) {
    final isPassed = state.progress!.status == 'completed';
    final accuracy = state.progress!.accuracyPercentage;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPassed ? Icons.check_circle : Icons.cancel,
                size: 100,
                color: isPassed ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                isPassed ? 'Congratulations!' : 'Taiken Failed',
                style: TextStyle(
                  color: isPassed ? Colors.green : Colors.red,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPassed
                      ? state.taiken!.outroSuccessScript
                      : state.taiken!.outroFailureScript,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              _buildResultStat(
                'Accuracy',
                '${accuracy.toStringAsFixed(1)}%',
                isPassed ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 12),
              _buildResultStat(
                'Correct Answers',
                '${state.progress!.correctAnswers}/${state.progress!.questionsAnswered}',
                Colors.blue,
              ),
              const SizedBox(height: 32),
              Text(
                'Rate this Taiken',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildRatingStars(state),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Taikens',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (!isPassed) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset and restart
                      ref.read(taikenExperienceProvider(widget.taikenId).notifier)
                          .reset();
                      ref.read(taikenExperienceProvider(widget.taikenId).notifier)
                          .loadTaiken();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildRatingStars(TaikenExperienceState state) {
  return StatefulBuilder(
    builder: (context, setState) {
      int selectedRating = 0;
      bool isSubmitted = false;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: isSubmitted ? null : () async {
                  setState(() => selectedRating = index + 1);
                  await ref
                      .read(taikenExperienceProvider(widget.taikenId).notifier)
                      .rateTaiken(selectedRating, null);
                  setState(() => isSubmitted = true);
                },
              );
            }),
          ),
          if (isSubmitted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Thank you for rating!',
                style: TextStyle(
                  color: Colors.green[400],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      );
    },
  );
}

  Widget _buildExperienceScreen(TaikenExperienceState state) {
    final hasDialogues = state.currentDialogues.isNotEmpty;
    final hasQuestions = state.currentQuestions.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Stage ${state.currentStageIndex + 1}/${state.stages.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${state.progress!.correctAnswers}/${state.progress!.questionsAnswered}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(state),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.currentStage?.sceneImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          state.currentStage!.sceneImageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[800],
                            child: const Icon(Icons.image_not_supported, size: 64),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Show dialogues
                    if (hasDialogues && state.hasMoreDialogues)
                      _buildDialogueSection(state)
                    // Show questions
                    else if (hasQuestions && state.hasMoreQuestions)
                      _buildQuestionSection(state)
                    else
                      const Center(child: Text('No content', style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(TaikenExperienceState state) {
    final totalQuestions = state.taiken!.totalQuestions;
    final answered = state.progress!.questionsAnswered;
    final progress = answered / totalQuestions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: ${answered}/${totalQuestions}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                'Accuracy: ${state.progress!.accuracyPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: state.progress!.accuracyPercentage >= state.taiken!.passThreshold
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= (state.taiken!.passThreshold / 100)
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueSection(TaikenExperienceState state) {
    final dialogue = state.currentDialogues[state.currentDialogueIndex];
    final character = state.characters.firstWhere(
          (c) => c.characterId == dialogue.characterId,
      orElse: () => TaikenCharacter(
        characterId: '',
        taikenId: '',
        characterName: 'Narrator',
        displayOrder: -1,
        createdAt: DateTime.now(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (character.characterImageUrl != null)
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(character.characterImageUrl!),
              )
            else
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[800],
                child: const Icon(Icons.person, color: Colors.white),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                character.characterName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Text(
            dialogue.dialogueText,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedAnswerIndex = null;
                _showExplanation = false;
              });
              ref.read(taikenExperienceProvider(widget.taikenId).notifier)
                  .advanceDialogue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionSection(TaikenExperienceState state) {
    final question = state.currentQuestions[state.currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue),
          ),
          child: Row(
            children: [
              const Icon(Icons.quiz, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(
          question.options.length,
              (index) => _buildOptionButton(
            question.options[index],
            index,
            question,
            state,
          ),
        ),
        if (_showExplanation && question.explanation != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[300],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Explanation',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.explanation!,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_selectedAnswerIndex != null) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedAnswerIndex = null;
                  _showExplanation = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionButton(
      String option,
      int index,
      TaikenQuestion question,
      TaikenExperienceState state,
      ) {
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = index == question.correctOptionIndex;
    final showResult = _selectedAnswerIndex != null;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.2);
        borderColor = Colors.green;
        textColor = Colors.green;
      } else if (isSelected) {
        backgroundColor = Colors.red.withOpacity(0.2);
        borderColor = Colors.red;
        textColor = Colors.red;
      } else {
        backgroundColor = Colors.grey[900]!;
        borderColor = Colors.grey[700]!;
        textColor = Colors.grey[400]!;
      }
    } else {
      backgroundColor = isSelected
          ? Colors.blue.withOpacity(0.2)
          : Colors.grey[900]!;
      borderColor = isSelected ? Colors.blue : Colors.grey[700]!;
      textColor = isSelected ? Colors.blue : Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _selectedAnswerIndex == null
            ? () {
          setState(() {
            _selectedAnswerIndex = index;
            _showExplanation = true;
          });
          ref.read(taikenExperienceProvider(widget.taikenId).notifier)
              .submitAnswer(question.questionId, index);
        }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                  color: isSelected || (showResult && isCorrect)
                      ? borderColor
                      : Colors.transparent,
                ),
                child: showResult && isCorrect
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : showResult && isSelected && !isCorrect
                    ? const Icon(Icons.close, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}