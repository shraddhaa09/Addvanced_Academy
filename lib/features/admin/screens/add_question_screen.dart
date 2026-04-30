import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class Subject {
  final String id;
  final String name;
  final String label;
  Subject({required this.id, required this.name, required this.label});
  factory Subject.fromMap(Map<String, dynamic> m) =>
      Subject(id: m['id'], name: m['name'], label: m['label']);
}

class Chapter {
  final String id;
  final String name;
  final int chapterNo;
  Chapter({required this.id, required this.name, required this.chapterNo});
  factory Chapter.fromMap(Map<String, dynamic> m) =>
      Chapter(id: m['id'], name: m['name'], chapterNo: m['chapter_no']);
}

class Topic {
  final String id;
  final String name;
  Topic({required this.id, required this.name});
  factory Topic.fromMap(Map<String, dynamic> m) =>
      Topic(id: m['id'], name: m['name']);
}

// ─── Providers ───────────────────────────────────────────────────────────────

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final data = await Supabase.instance.client
      .from('subjects')
      .select('id, name, label')
      .order('label');
  return (data as List).map((e) => Subject.fromMap(e)).toList();
});

final chaptersProvider = FutureProvider.family<List<Chapter>, String>((
  ref,
  subjectId,
) async {
  final data = await Supabase.instance.client
      .from('chapters')
      .select('id, name, chapter_no')
      .eq('subject_id', subjectId)
      .order('chapter_no');
  return (data as List).map((e) => Chapter.fromMap(e)).toList();
});

final topicsProvider = FutureProvider.family<List<Topic>, String>((
  ref,
  chapterId,
) async {
  final data = await Supabase.instance.client
      .from('topics')
      .select('id, name')
      .eq('chapter_id', chapterId)
      .order('topic_no');
  return (data as List).map((e) => Topic.fromMap(e)).toList();
});

// ─── Form State ───────────────────────────────────────────────────────────────

class AddQuestionFormState {
  final Subject? selectedSubject;
  final Chapter? selectedChapter;
  final Topic? selectedTopic;
  final String topicInput; // manual topic entry
  final String questionBody;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption; // 'a','b','c','d'
  final double marksCorrect;
  final double marksWrong;
  final int difficulty; // 1–5
  final bool isActive;
  final bool isPreviewExpanded;
  final bool isSaving;

  const AddQuestionFormState({
    this.selectedSubject,
    this.selectedChapter,
    this.selectedTopic,
    this.topicInput = '',
    this.questionBody = '',
    this.optionA = '',
    this.optionB = '',
    this.optionC = '',
    this.optionD = '',
    this.correctOption = 'a',
    this.marksCorrect = 2.0,
    this.marksWrong = -0.50,
    this.difficulty = 3,
    this.isActive = true,
    this.isPreviewExpanded = false,
    this.isSaving = false,
  });

  AddQuestionFormState copyWith({
    Subject? selectedSubject,
    bool clearSubject = false,
    Chapter? selectedChapter,
    bool clearChapter = false,
    Topic? selectedTopic,
    bool clearTopic = false,
    String? topicInput,
    String? questionBody,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
    double? marksCorrect,
    double? marksWrong,
    int? difficulty,
    bool? isActive,
    bool? isPreviewExpanded,
    bool? isSaving,
  }) {
    return AddQuestionFormState(
      selectedSubject: clearSubject
          ? null
          : (selectedSubject ?? this.selectedSubject),
      selectedChapter: clearChapter
          ? null
          : (selectedChapter ?? this.selectedChapter),
      selectedTopic: clearTopic ? null : (selectedTopic ?? this.selectedTopic),
      topicInput: topicInput ?? this.topicInput,
      questionBody: questionBody ?? this.questionBody,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctOption: correctOption ?? this.correctOption,
      marksCorrect: marksCorrect ?? this.marksCorrect,
      marksWrong: marksWrong ?? this.marksWrong,
      difficulty: difficulty ?? this.difficulty,
      isActive: isActive ?? this.isActive,
      isPreviewExpanded: isPreviewExpanded ?? this.isPreviewExpanded,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class AddQuestionNotifier extends StateNotifier<AddQuestionFormState> {
  AddQuestionNotifier() : super(const AddQuestionFormState());

  void selectSubject(Subject s) => state = state.copyWith(
    selectedSubject: s,
    clearChapter: true,
    clearTopic: true,
  );

  void selectChapter(Chapter c) =>
      state = state.copyWith(selectedChapter: c, clearTopic: true);

  void selectTopic(Topic t) => state = state.copyWith(selectedTopic: t);

  void setTopicInput(String v) => state = state.copyWith(topicInput: v);
  void setQuestionBody(String v) => state = state.copyWith(questionBody: v);
  void setOptionA(String v) => state = state.copyWith(optionA: v);
  void setOptionB(String v) => state = state.copyWith(optionB: v);
  void setOptionC(String v) => state = state.copyWith(optionC: v);
  void setOptionD(String v) => state = state.copyWith(optionD: v);
  void setCorrectOption(String v) => state = state.copyWith(correctOption: v);
  void setMarksCorrect(double v) => state = state.copyWith(marksCorrect: v);
  void setMarksWrong(double v) => state = state.copyWith(marksWrong: v);
  void setDifficulty(int v) => state = state.copyWith(difficulty: v);
  void setActive(bool v) => state = state.copyWith(isActive: v);
  void togglePreview() =>
      state = state.copyWith(isPreviewExpanded: !state.isPreviewExpanded);

  void reset() => state = const AddQuestionFormState();

  Future<void> save(BuildContext context, String adminUserId) async {
    final s = state;
    if (s.isSaving) return;

    // Resolve topic id
    String? topicId = s.selectedTopic?.id;

    // If no topic selected but chapter selected → find or create topic
    if (topicId == null &&
        s.selectedChapter != null &&
        s.topicInput.trim().isNotEmpty) {
      // Try to find existing topic by name
      final existing = await Supabase.instance.client
          .from('topics')
          .select('id')
          .eq('chapter_id', s.selectedChapter!.id)
          .eq('name', s.topicInput.trim())
          .maybeSingle();

      if (existing != null) {
        topicId = existing['id'] as String;
      } else {
        // Get max topic_no
        final maxResult = await Supabase.instance.client
            .from('topics')
            .select('topic_no')
            .eq('chapter_id', s.selectedChapter!.id)
            .order('topic_no', ascending: false)
            .limit(1)
            .maybeSingle();
        final nextNo = ((maxResult?['topic_no'] as int?) ?? 0) + 1;

        final inserted = await Supabase.instance.client
            .from('topics')
            .insert({
              'chapter_id': s.selectedChapter!.id,
              'name': s.topicInput.trim(),
              'topic_no': nextNo,
            })
            .select('id')
            .single();
        topicId = inserted['id'] as String;
      }
    }

    state = state.copyWith(isSaving: true);

    try {
      await Supabase.instance.client.from('questions').insert({
        'topic_id': topicId,
        'body': s.questionBody.trim(),
        'option_a': s.optionA.trim(),
        'option_b': s.optionB.trim(),
        'option_c': s.optionC.trim(),
        'option_d': s.optionD.trim(),
        'correct_option': s.correctOption,
        'marks_correct': s.marksCorrect,
        'marks_wrong': s.marksWrong,
        'difficulty': s.difficulty,
        'is_active': s.isActive,
        'created_by': adminUserId,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question saved successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        reset();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final addQuestionProvider =
    StateNotifierProvider.autoDispose<
      AddQuestionNotifier,
      AddQuestionFormState
    >((ref) => AddQuestionNotifier());

// ─── Screen ───────────────────────────────────────────────────────────────────

class AddQuestionScreen extends ConsumerStatefulWidget {
  const AddQuestionScreen({
    super.key,
    this.prefilledSubject,
    this.prefilledChapterId,
  });

  final String? prefilledSubject;
  final String? prefilledChapterId;

  @override
  ConsumerState<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends ConsumerState<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _optACtrl = TextEditingController();
  final _optBCtrl = TextEditingController();
  final _optCCtrl = TextEditingController();
  final _optDCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();

  // For sync between notifier and controllers on reset
  @override
  void dispose() {
    _questionCtrl.dispose();
    _optACtrl.dispose();
    _optBCtrl.dispose();
    _optCCtrl.dispose();
    _optDCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  void _resetControllers() {
    _questionCtrl.clear();
    _optACtrl.clear();
    _optBCtrl.clear();
    _optCCtrl.clear();
    _optDCtrl.clear();
    _topicCtrl.clear();
  }

  // Dummy admin id — replace with your actual auth provider lookup
  String get _adminUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(addQuestionProvider);
    final notifier = ref.read(addQuestionProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(context, formState, notifier),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AcademicMappingCard(
              formState: formState,
              notifier: notifier,
              topicCtrl: _topicCtrl,
            ),
            const SizedBox(height: 16),
            _QuestionContentCard(
              formState: formState,
              notifier: notifier,
              questionCtrl: _questionCtrl,
            ),
            const SizedBox(height: 16),
            _OptionsKeyCard(
              formState: formState,
              notifier: notifier,
              optACtrl: _optACtrl,
              optBCtrl: _optBCtrl,
              optCCtrl: _optCCtrl,
              optDCtrl: _optDCtrl,
            ),
            const SizedBox(height: 16),
            _MarkingSchemeCard(formState: formState, notifier: notifier),
            const SizedBox(height: 16),
            _QuestionPreviewCard(formState: formState, notifier: notifier),
            const SizedBox(height: 24),
            _SaveButton(
              isSaving: formState.isSaving,
              onSave: () {
                if (_validate(formState)) {
                  notifier.save(context, _adminUserId);
                }
              },
            ),
            const SizedBox(height: 12),
            _ResetButton(
              onReset: () {
                notifier.reset();
                _resetControllers();
                _formKey.currentState?.reset();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  bool _validate(AddQuestionFormState s) {
    bool valid = true;
    final msgs = <String>[];

    if (s.selectedSubject == null) msgs.add('Please select a subject');
    if (s.selectedChapter == null) msgs.add('Please select a chapter');
    if (s.selectedTopic == null && s.topicInput.trim().isEmpty) {
      msgs.add('Please enter or select a topic');
    }
    if (s.questionBody.trim().length < 5) msgs.add('Question text is required');
    if (s.optionA.trim().isEmpty) msgs.add('Option A is required');
    if (s.optionB.trim().isEmpty) msgs.add('Option B is required');
    if (s.optionC.trim().isEmpty) msgs.add('Option C is required');
    if (s.optionD.trim().isEmpty) msgs.add('Option D is required');

    if (msgs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msgs.first),
          backgroundColor: Colors.red.shade700,
        ),
      );
      valid = false;
    }
    return valid;
  }

  AppBar _buildAppBar(
    BuildContext context,
    AddQuestionFormState formState,
    AddQuestionNotifier notifier,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Add Question',
        style: TextStyle(
          color: Color(0xFF1A1A2E),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.save_rounded, color: Color(0xFF4F46E5)),
          onPressed: formState.isSaving
              ? null
              : () {
                  if (_validate(formState)) {
                    notifier.save(context, _adminUserId);
                  }
                },
        ),
      ],
    );
  }
}

// ─── Academic Mapping Card ────────────────────────────────────────────────────

class _AcademicMappingCard extends ConsumerWidget {
  final AddQuestionFormState formState;
  final AddQuestionNotifier notifier;
  final TextEditingController topicCtrl;

  const _AcademicMappingCard({
    required this.formState,
    required this.notifier,
    required this.topicCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final chaptersAsync = formState.selectedSubject != null
        ? ref.watch(chaptersProvider(formState.selectedSubject!.id))
        : null;
    final topicsAsync = formState.selectedChapter != null
        ? ref.watch(topicsProvider(formState.selectedChapter!.id))
        : null;

    return _SectionCard(
      icon: Icons.school_rounded,
      iconColor: const Color(0xFF4F46E5),
      title: 'Academic Mapping',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject dropdown
          _FieldLabel('SUBJECT'),
          const SizedBox(height: 6),
          subjectsAsync.when(
            data: (subjects) => _StyledDropdown<Subject>(
              hint: 'Select Subject',
              value: formState.selectedSubject,
              items: subjects,
              itemLabel: (s) => s.label,
              onChanged: (s) {
                if (s != null) notifier.selectSubject(s);
              },
            ),
            loading: () => const _LoadingDropdown(),
            error: (e, _) => _ErrorDropdown(error: e.toString()),
          ),

          const SizedBox(height: 14),

          // Chapter dropdown
          _FieldLabel('CHAPTER'),
          const SizedBox(height: 6),
          if (formState.selectedSubject == null)
            const _DisabledDropdown(hint: 'Select Chapter')
          else
            chaptersAsync!.when(
              data: (chapters) => _StyledDropdown<Chapter>(
                hint: 'Select Chapter',
                value: formState.selectedChapter,
                items: chapters,
                itemLabel: (c) => 'Ch ${c.chapterNo}: ${c.name}',
                onChanged: (c) {
                  if (c != null) notifier.selectChapter(c);
                },
              ),
              loading: () => const _LoadingDropdown(),
              error: (e, _) => _ErrorDropdown(error: e.toString()),
            ),

          const SizedBox(height: 14),

          // Topic — dropdown if topics exist, else text field
          _FieldLabel('TOPIC'),
          const SizedBox(height: 6),
          if (formState.selectedChapter == null)
            const _DisabledDropdown(hint: 'Enter Topic Name')
          else
            topicsAsync!.when(
              data: (topics) {
                if (topics.isEmpty) {
                  // Free-text entry
                  return _StyledTextField(
                    controller: topicCtrl,
                    hint: 'Enter Topic Name',
                    onChanged: notifier.setTopicInput,
                  );
                }
                // Show dropdown + allow new
                return Column(
                  children: [
                    _StyledDropdown<Topic>(
                      hint: 'Select Topic',
                      value: formState.selectedTopic,
                      items: topics,
                      itemLabel: (t) => t.name,
                      onChanged: (t) {
                        if (t != null) notifier.selectTopic(t);
                      },
                    ),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: topicCtrl,
                      hint: 'Or enter new topic name',
                      onChanged: notifier.setTopicInput,
                    ),
                  ],
                );
              },
              loading: () => const _LoadingDropdown(),
              error: (e, _) => _ErrorDropdown(error: e.toString()),
            ),
        ],
      ),
    );
  }
}

// ─── Question Content Card ────────────────────────────────────────────────────

class _QuestionContentCard extends StatelessWidget {
  final AddQuestionFormState formState;
  final AddQuestionNotifier notifier;
  final TextEditingController questionCtrl;

  const _QuestionContentCard({
    required this.formState,
    required this.notifier,
    required this.questionCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.description_rounded,
      iconColor: const Color(0xFFE67E22),
      title: 'Question Content',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('QUESTION BODY'),
          const SizedBox(height: 6),
          TextFormField(
            controller: questionCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: 'Type your academic question here...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            onChanged: notifier.setQuestionBody,
          ),
          if (formState.questionBody.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Question text is required',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Options & Key Card ───────────────────────────────────────────────────────

class _OptionsKeyCard extends StatelessWidget {
  final AddQuestionFormState formState;
  final AddQuestionNotifier notifier;
  final TextEditingController optACtrl;
  final TextEditingController optBCtrl;
  final TextEditingController optCCtrl;
  final TextEditingController optDCtrl;

  const _OptionsKeyCard({
    required this.formState,
    required this.notifier,
    required this.optACtrl,
    required this.optBCtrl,
    required this.optCCtrl,
    required this.optDCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('A', 'a', optACtrl, notifier.setOptionA),
      ('B', 'b', optBCtrl, notifier.setOptionB),
      ('C', 'c', optCCtrl, notifier.setOptionC),
      ('D', 'd', optDCtrl, notifier.setOptionD),
    ];

    return _SectionCard(
      icon: Icons.grid_on_rounded,
      iconColor: const Color(0xFF27AE60),
      title: 'Options & Key',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...options.map((opt) {
            final label = opt.$1;
            final key = opt.$2;
            final ctrl = opt.$3;
            final onChanged = opt.$4;
            final isCorrect = formState.correctOption == key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFF0F0F5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isCorrect
                              ? Colors.white
                              : const Color(0xFF666680),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Option $label',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isCorrect
                                ? const Color(0xFF4F46E5)
                                : Colors.grey.shade200,
                            width: isCorrect ? 1.5 : 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isCorrect
                                ? const Color(0xFF4F46E5)
                                : Colors.grey.shade200,
                            width: isCorrect ? 1.5 : 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          _FieldLabel('CORRECT ANSWER'),
          const SizedBox(height: 10),
          Row(
            children: ['A', 'B', 'C', 'D'].map((l) {
              final key = l.toLowerCase();
              final isSelected = formState.correctOption == key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => notifier.setCorrectOption(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          l,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF555580),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Marking Scheme Card ──────────────────────────────────────────────────────

class _MarkingSchemeCard extends StatelessWidget {
  final AddQuestionFormState formState;
  final AddQuestionNotifier notifier;

  const _MarkingSchemeCard({required this.formState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final diffLabels = ['', 'Very Easy', 'Easy', 'Medium', 'Hard', 'Very Hard'];

    return _SectionCard(
      icon: Icons.format_list_numbered_rounded,
      iconColor: const Color(0xFF4F46E5),
      title: 'Marking Scheme',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('CORRECT MARKS'),
                    const SizedBox(height: 6),
                    _MarksField(
                      value: formState.marksCorrect,
                      prefix: '+',
                      prefixColor: const Color(0xFF27AE60),
                      onChanged: (v) => notifier.setMarksCorrect(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('NEGATIVE MARKS'),
                    const SizedBox(height: 6),
                    _MarksField(
                      value: formState.marksWrong,
                      prefix: '−',
                      prefixColor: Colors.red,
                      onChanged: (v) => notifier.setMarksWrong(v),
                      isNegative: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FieldLabel('DIFFICULTY LEVEL'),
              Text(
                diffLabels[formState.difficulty],
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4F46E5),
              inactiveTrackColor: const Color(0xFFE0E0F0),
              thumbColor: const Color(0xFF4F46E5),
              overlayColor: const Color(0x204F46E5),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 4,
            ),
            child: Slider(
              value: formState.difficulty.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => notifier.setDifficulty(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EASY',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'HARD',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF27AE60),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Active Question',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Switch(
                value: formState.isActive,
                onChanged: notifier.setActive,
                activeColor: const Color(0xFF4F46E5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Question Preview Card ────────────────────────────────────────────────────

class _QuestionPreviewCard extends StatelessWidget {
  final AddQuestionFormState formState;
  final AddQuestionNotifier notifier;

  const _QuestionPreviewCard({required this.formState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final options = {
      'A': formState.optionA,
      'B': formState.optionB,
      'C': formState.optionC,
      'D': formState.optionD,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: notifier.togglePreview,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.remove_red_eye_rounded,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Question Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: formState.isPreviewExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF9090A0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  if (formState.questionBody.isNotEmpty)
                    Text(
                      formState.questionBody,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                        height: 1.5,
                      ),
                    )
                  else
                    Text(
                      'No question entered yet.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 12),
                  ...options.entries.map((e) {
                    final isCorrect =
                        e.key.toLowerCase() == formState.correctOption;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFF0F0F5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  color: isCorrect
                                      ? Colors.white
                                      : const Color(0xFF666680),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value.isEmpty ? '—' : e.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: isCorrect
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFF444460),
                                fontWeight: isCorrect
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isCorrect)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF27AE60),
                              size: 16,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            crossFadeState: formState.isPreviewExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ─── Buttons ──────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveButton({required this.isSaving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSaving ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Question',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onReset;
  const _ResetButton({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onReset,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF666680),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Reset Form',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const _StyledDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(
        hint,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      items: items
          .map(
            (i) => DropdownMenuItem<T>(
              value: i,
              child: Text(
                itemLabel(i),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF9090A0),
      ),
      dropdownColor: Colors.white,
      isExpanded: true,
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(String) onChanged;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _DisabledDropdown extends StatelessWidget {
  final String hint;
  const _DisabledDropdown({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFB0B0C0),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _LoadingDropdown extends StatelessWidget {
  const _LoadingDropdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4F46E5),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Loading...',
            style: TextStyle(fontSize: 14, color: Color(0xFF9090A0)),
          ),
        ],
      ),
    );
  }
}

class _ErrorDropdown extends StatelessWidget {
  final String error;
  const _ErrorDropdown({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Error loading data',
              style: TextStyle(fontSize: 13, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarksField extends StatelessWidget {
  final double value;
  final String prefix;
  final Color prefixColor;
  final bool isNegative;
  final void Function(double) onChanged;

  const _MarksField({
    required this.value,
    required this.prefix,
    required this.prefixColor,
    required this.onChanged,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            decoration: BoxDecoration(
              color: prefixColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                prefix,
                style: TextStyle(
                  color: prefixColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: value.abs().toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v) ?? 0;
                onChanged(isNegative ? -parsed : parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
