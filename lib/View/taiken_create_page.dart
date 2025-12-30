import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ViewModel/taiken_create_provider.dart';
import 'dart:io';

class TaikenCreatePage extends ConsumerStatefulWidget {
  const TaikenCreatePage({super.key});

  @override
  ConsumerState<TaikenCreatePage> createState() => _TaikenCreatePageState();
}

class _TaikenCreatePageState extends ConsumerState<TaikenCreatePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _introScriptController = TextEditingController();
  final _outroSuccessController = TextEditingController();
  final _outroFailureController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _introScriptController.dispose();
    _outroSuccessController.dispose();
    _outroFailureController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taikenCreateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: const Text('Create Taiken'),
        actions: [
          if (_currentPage == 4)
            TextButton(
              onPressed: state.isLoading ? null : _handleCreate,
              child: state.isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Publish'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildBasicInfoPage(),
                _buildScriptsPage(),
                _buildCharactersPage(),
                _buildStagesPage(),
                _buildReviewPage(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index == _currentPage;
          final isCompleted = index < _currentPage;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : isActive
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                    : Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final state = ref.watch(taikenCreateProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == 4
                  ? (state.isLoading ? null : _handleCreate)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_currentPage == 4 ? 'Publish Taiken' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    final state = ref.watch(taikenCreateProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Thumbnail
          GestureDetector(
            onTap: () => ref.read(taikenCreateProvider.notifier).pickThumbnail(),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: state.thumbnailFile != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(state.thumbnailFile!.path),
                  fit: BoxFit.cover,
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Add Thumbnail',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          TextField(
            controller: _titleController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Taiken Title',
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) =>
                ref.read(taikenCreateProvider.notifier).updateTitle(value),
          ),
          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descriptionController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) =>
                ref.read(taikenCreateProvider.notifier).updateDescription(value),
          ),
          const SizedBox(height: 16),

          // Domain
          DropdownButtonFormField<String>(
            value: state.domain.isEmpty ? null : state.domain,
            dropdownColor: Theme.of(context).cardColor,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Domain',
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ['Science', 'Business', 'History', 'Technology', 'Arts']
                .map((domain) => DropdownMenuItem(
              value: domain,
              child: Text(domain),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(taikenCreateProvider.notifier).updateDomain(value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Difficulty
          DropdownButtonFormField<String>(
            value: state.difficulty,
            dropdownColor: Theme.of(context).cardColor,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Difficulty',
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ['beginner', 'intermediate', 'advanced']
                .map((diff) => DropdownMenuItem(
              value: diff,
              child: Text(diff[0].toUpperCase() + diff.substring(1)),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(taikenCreateProvider.notifier).updateDifficulty(value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Total Stages
          TextField(
            keyboardType: TextInputType.number,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Number of Stages',
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              final count = int.tryParse(value);
              if (count != null && count > 0) {
                ref.read(taikenCreateProvider.notifier).setTotalStages(count);
              }
            },
          ),
        ],
      ),
    );
  }
  Widget _buildScriptsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Story Scripts',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Write the intro and outro narratives for your Taiken',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          // Intro Script
          Text(
            'Introduction',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _introScriptController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Write the opening narrative that sets the stage...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) =>
                ref.read(taikenCreateProvider.notifier).updateIntroScript(value),
          ),
          const SizedBox(height: 24),

          // Success Outro
          Text(
            'Success Outro',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _outroSuccessController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'What happens when the user succeeds...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => ref
                .read(taikenCreateProvider.notifier)
                .updateOutroSuccessScript(value),
          ),
          const SizedBox(height: 24),

          // Failure Outro
          Text(
            'Failure Outro',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _outroFailureController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'What happens when the user fails...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => ref
                .read(taikenCreateProvider.notifier)
                .updateOutroFailureScript(value),
          ),
        ],
      ),
    );
  }
  Widget _buildStagesPage() {
    final state = ref.watch(taikenCreateProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Configure Stages',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.stages.length,
            itemBuilder: (context, index) => _buildStageCard(index),
          ),
        ),
      ],
    );
  }
  Widget _buildStageCard(int stageIndex) {
    final state = ref.watch(taikenCreateProvider);
    final stage = state.stages[stageIndex];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          'Stage ${stageIndex + 1}: ${stage.stageTitle}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stage scene image
                GestureDetector(
                  onTap: () => ref
                      .read(taikenCreateProvider.notifier)
                      .pickStageScene(stageIndex),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: stage.sceneImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(stage.sceneImage!.path),
                        fit: BoxFit.cover,
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.landscape,
                            size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Add Scene Image',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dialogues
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dialogues',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () => ref
                          .read(taikenCreateProvider.notifier)
                          .addDialogue(stageIndex),
                    ),
                  ],
                ),
                ...List.generate(
                  stage.dialogues.length,
                      (dialogueIndex) => _buildDialogueField(stageIndex, dialogueIndex),
                ),
                const SizedBox(height: 16),

                // Questions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questions',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () => ref
                          .read(taikenCreateProvider.notifier)
                          .addQuestion(stageIndex),
                    ),
                  ],
                ),
                ...List.generate(
                  stage.questions.length,
                      (questionIndex) => _buildQuestionField(stageIndex, questionIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDialogueField(int stageIndex, int dialogueIndex) {
    final state = ref.watch(taikenCreateProvider);
    final dialogue = state.stages[stageIndex].dialogues[dialogueIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: dialogue.characterTempId,
                  dropdownColor: Theme.of(context).cardColor,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Character',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Narrator'),
                    ),
                    ...state.characters.map(
                          (char) => DropdownMenuItem(
                        value: char.tempId,
                        child: Text(char.characterName),
                      ),
                    ),
                  ],
                  onChanged: (value) => ref
                      .read(taikenCreateProvider.notifier)
                      .updateDialogue(
                    stageIndex,
                    dialogueIndex,
                    dialogue.dialogueText,
                    characterTempId: value,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                onPressed: () => ref
                    .read(taikenCreateProvider.notifier)
                    .removeDialogue(stageIndex, dialogueIndex),
              ),
            ],
          ),
          TextField(
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Enter dialogue text...',
              border: InputBorder.none,
            ),
            onChanged: (value) => ref
                .read(taikenCreateProvider.notifier)
                .updateDialogue(
              stageIndex,
              dialogueIndex,
              value,
              characterTempId: dialogue.characterTempId,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildQuestionField(int stageIndex, int questionIndex) {
    final state = ref.watch(taikenCreateProvider);
    final question = state.stages[stageIndex].questions[questionIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Question text...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => ref
                      .read(taikenCreateProvider.notifier)
                      .updateQuestion(
                    stageIndex,
                    questionIndex,
                    question.copyWith(questionText: value),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                onPressed: () => ref
                    .read(taikenCreateProvider.notifier)
                    .removeQuestion(stageIndex, questionIndex),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(
            question.options.length,
                (optionIndex) => _buildOptionField(
              stageIndex,
              questionIndex,
              optionIndex,
              question,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOptionField(
      int stageIndex,
      int questionIndex,
      int optionIndex,
      QuestionData question,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Radio<int>(
            value: optionIndex,
            groupValue: question.correctOptionIndex,
            onChanged: (value) {
              if (value != null) {
                ref.read(taikenCreateProvider.notifier).updateQuestion(
                  stageIndex,
                  questionIndex,
                  question.copyWith(correctOptionIndex: value),
                );
              }
            },
          ),
          Expanded(
            child: TextField(
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Option ${optionIndex + 1}',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                final updatedOptions = List<String>.from(question.options);
                updatedOptions[optionIndex] = value;
                ref.read(taikenCreateProvider.notifier).updateQuestion(
                  stageIndex,
                  questionIndex,
                  question.copyWith(options: updatedOptions),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCharactersPage() {
    final state = ref.watch(taikenCreateProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Characters',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(taikenCreateProvider.notifier).addCharacter(),
                icon: const Icon(Icons.add),
                label: const Text('Add Character'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.characters.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No characters yet',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.characters.length,
            itemBuilder: (context, index) => _buildCharacterCard(index),
          ),
        ),
      ],
    );
  }
  Widget _buildCharacterCard(int index) {
    final state = ref.watch(taikenCreateProvider);
    final character = state.characters[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref
                  .read(taikenCreateProvider.notifier)
                  .pickCharacterImage(index),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: character.characterImage != null
                    ? ClipOval(
                  child: Image.file(
                    File(character.characterImage!.path),
                    fit: BoxFit.cover,
                  ),
                )
                    : Icon(Icons.person, size: 40, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Character name',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => ref
                        .read(taikenCreateProvider.notifier)
                        .updateCharacter(
                      index,
                      character.copyWith(characterName: value),
                    ),
                  ),
                  TextField(
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => ref
                        .read(taikenCreateProvider.notifier)
                        .updateCharacter(
                      index,
                      character.copyWith(characterDescription: value),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => ref
                  .read(taikenCreateProvider.notifier)
                  .removeCharacter(index),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildReviewPage() {
    final state = ref.watch(taikenCreateProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Publish',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          _buildReviewItem('Title', state.title),
          _buildReviewItem('Domain', state.domain),
          _buildReviewItem('Difficulty', state.difficulty),
          _buildReviewItem('Stages', '${state.totalStages}'),
          _buildReviewItem(
            'Total Questions',
            state.stages.fold<int>(
              0,
                  (sum, stage) => sum + stage.questions.length,
            ).toString(),
          ),
          _buildReviewItem('Characters', '${state.characters.length}'),

          const SizedBox(height: 24),
          if (state.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _handleCreate() async {
    final success = await ref.read(taikenCreateProvider.notifier).createTaiken();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taiken published successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}