import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' as io;

import '../../../core/errors/app_exceptions.dart';
import '../../../models/chapter_model.dart';
import '../../../models/subject_model.dart';
import '../../../providers/faculty_providers.dart';

class UploadVideoScreen extends ConsumerStatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  ConsumerState<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends ConsumerState<UploadVideoScreen> {
  static const _primary = Color(0xFF5B4FCF);
  static const _maxFileSizeBytes = 500 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  SubjectModel? _selectedSubject;
  ChapterModel? _selectedChapter;
  List<ChapterModel> _chapters = [];
  bool _isLoadingChapters = false;
  String? _chapterError;

  dynamic _fileData; // io.File or Uint8List
  String? _fileName;
  String? _fileSizeLabel;
  String? _fileError;
  int? _fileSizeBytes;
  bool _isVisible = true;
  bool _isUploading = false;

  bool get _isDirty =>
      _titleController.text.isNotEmpty ||
          _descriptionController.text.isNotEmpty ||
          _selectedSubject != null ||
          _selectedChapter != null ||
          _fileData != null;

  bool get _canSubmit =>
      _selectedSubject != null &&
          _selectedChapter != null &&
          _fileData != null &&
          _fileError == null &&
          _titleController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters(SubjectModel? subject) async {
    setState(() {
      _selectedSubject = subject;
      _selectedChapter = null;
      _chapters = [];
      _chapterError = null;
      _isLoadingChapters = subject != null;
    });

    if (subject == null) return;

    try {
      final service = ref.read(chapterServiceProvider);
      final chapters = await service.fetchChaptersBySubject(subject.id as String);

      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _isLoadingChapters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chapters = [];
        _isLoadingChapters = false;
        _chapterError =
        'Error: ${e.toString().replaceAll('Exception:', '').trim()}';
      });
    }
  }



  void _clearFile() {
    setState(() {
      _fileData = null;
      _fileName = null;
      _fileSizeLabel = null;
      _fileSizeBytes = null;
      _fileError = null;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => const _DiscardDialog(),
    );
    return discard ?? false;
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: kIsWeb, // Needed for web
      );
      if (result == null || result.files.single.name.isEmpty) return;

      final name = result.files.single.name;
      final sizeBytes = result.files.single.size;

      if (sizeBytes > _maxFileSizeBytes) {
        setState(() {
          _fileData = null;
          _fileName = null;
          _fileSizeLabel = null;
          _fileSizeBytes = null;
          _fileError = 'File too large. Maximum size is 500 MB.';
        });
        return;
      }

      final sizeLabel = sizeBytes >= 1024 * 1024
          ? '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '${(sizeBytes / 1024).toStringAsFixed(0)} KB';

      setState(() {
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          if (bytes == null) {
            throw Exception('Failed to read file bytes');
          }
          _fileData = bytes;
        } else {
          final path = result.files.single.path;
          if (path == null) {
            throw Exception('File path is null');
          }
          _fileData = io.File(path);
        }
        _fileName = name;
        _fileSizeLabel = sizeLabel;
        _fileSizeBytes = sizeBytes;
        _fileError = null;
      });
    } catch (e) {
      setState(() {
        _fileError = 'Picker error: $e';
      });
    }
  }



  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    // Ensure we have all required selections
    if (_selectedSubject == null || _selectedChapter == null || _fileData == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. Get the ID from the provider (await if it's a FutureProvider)
      final facultyId = await ref.read(currentFacultyIdProvider.future);
      if (facultyId == null) throw Exception('Could not determine faculty ID');

      final videoService = ref.read(videoServiceProvider);

      // 2. Use the IDs from your selected models
      final String subjectId = _selectedSubject!.id;
      final String chapterId = _selectedChapter!.id;

      // 3. Upload the actual file to storage
      final storagePath = await videoService.uploadVideoFile(
        fileName: _fileName!,
        file: _fileData!,
        facultyId: facultyId,
        subjectId: subjectId,
        chapterId: chapterId,
      );

      // 4. Create the database record
      await videoService.createVideoLecture(
        facultyId: facultyId,
        subjectId: subjectId,
        chapterId: chapterId,
        title: _titleController.text.trim(),
        storagePath: storagePath,
        description: _descriptionController.text.trim(),
        fileSizeKb: (_fileSizeBytes! / 1024).round(),
        isVisible: _isVisible,
      );

      // Refresh the dashboard list
      ref.invalidate(recentFacultyUploadsProvider);

      if (!mounted) return;
      setState(() => _isUploading = false);
      _showSuccessSheet();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showErrorSheet(e.toString());
    }
  }



  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SuccessSheet(
        title: _titleController.text.trim(),
        onDashboard: () {
          Navigator.of(context).pop();
          context.pop();
        },
        onUploadAnother: () {
          Navigator.of(context).pop();
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedSubject = null;
            _selectedChapter = null;
            _chapters = [];
            _fileData = null;
            _fileName = null;
            _fileSizeLabel = null;
            _isVisible = true;
          });
        },
      ),
    );
  }

  void _showErrorSheet(String message) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ErrorSheet(
        message: message,
        onRetry: () => Navigator.of(context).pop(),
        onCancel: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (_) => const _DiscardDialog(),
        );
        if ((discard ?? false) && context.mounted) context.pop();
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            appBar: _buildAppBar(),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                onChanged: () => setState(() {}),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilePicker(
                      selectedFile: _fileData,
                      fileName: _fileName,
                      fileSizeLabel: _fileSizeLabel,
                      fileError: _fileError,
                      onTap: _pickVideo,
                      onClear: _clearFile,
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel('Lecture Title'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 100,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) {
                        if (currentLength < 80) return null;
                        return Text(
                          '$currentLength/$maxLength',
                          style: TextStyle(
                            fontSize: 11,
                            color: currentLength >= 100 ? Colors.red : Colors.grey,
                          ),
                        );
                      },
                      decoration: _inputDecoration('e.g. Kinematics — Part 1'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Subject'),
                    const SizedBox(height: 6),
                    subjectsAsync.when(
                      data: (subjects) => DropdownButtonFormField<SubjectModel>(
                        value: _selectedSubject,
                        decoration: _inputDecoration('Select subject'),
                        items: subjects
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                            .toList(),
                        onChanged: (val) {
                          _loadChapters(val);
                        },
                        validator: (v) => v == null ? 'Please select a subject' : null,
                      ),
                      loading: () => const _SkeletonField(),
                      error: (e, _) => const _ErrorField('Could not load subjects'),
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Chapter'),
                    const SizedBox(height: 6),
                    if (_isLoadingChapters)
                      const _SkeletonField()
                    else if (_chapterError != null)
                      _ErrorField(_chapterError!, onRetry: () => _loadChapters(_selectedSubject))
                    else if (_selectedSubject != null && _chapters.isEmpty)
                      const _ErrorField('No chapters found for this subject. Please add chapters first.')
                    else
                      DropdownButtonFormField<ChapterModel>(
                        value: _selectedChapter,
                        decoration: _inputDecoration(_selectedSubject == null ? 'Select subject first' : 'Select chapter'),
                        items: _chapters
                            .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        ))
                            .toList(),
                        onChanged: _selectedSubject == null || _chapters.isEmpty
                            ? null
                            : (val) => setState(() => _selectedChapter = val),
                        validator: (v) => v == null ? 'Please select a chapter' : null,
                      ),
                    const SizedBox(height: 16),
                    _FieldLabel('Notes (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration('Brief description of this lecture'),
                      maxLines: 3,
                      maxLength: 300,
                    ),
                    const SizedBox(height: 16),
                    _VisibilityToggle(
                      value: _isVisible,
                      onChanged: (v) => setState(() => _isVisible = v),
                    ),
                    const SizedBox(height: 32),
                    _UploadButton(
                      enabled: _canSubmit,
                      onTap: _upload,
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        "Files are stored in Addvanced Academy's secure cloud.",
                        style: TextStyle(fontSize: 11, color: Color(0xFFB0B0B0)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isUploading) const _UploadOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: const Color(0xFF1A1A2E),
      title: const Text(
        'Upload Video Lecture',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: const Color(0xFFEEEEEE)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}

class _FilePicker extends StatelessWidget {
  final dynamic selectedFile;
  final String? fileName;
  final String? fileSizeLabel;
  final String? fileError;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _FilePicker({
    required this.selectedFile,
    required this.fileName,
    required this.fileSizeLabel,
    required this.fileError,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedFile == null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: fileError != null ? const Color(0xFFE53935) : const Color(0xFFDDDDDD),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEECFD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.video_call_rounded,
                      color: Color(0xFF5B4FCF),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap to select video',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'MP4, MOV, AVI · Max 500 MB',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF5B4FCF).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Color(0xFF5B4FCF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileSizeLabel ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5B4FCF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (fileError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFE53935)),
              const SizedBox(width: 4),
              Text(
                fileError!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE53935)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _VisibilityToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Visible to students',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        subtitle: const Text(
          'Published immediately after upload',
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF5B4FCF),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _UploadButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B4FCF),
            disabledBackgroundColor: const Color(0xFF5B4FCF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Upload Video',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadOverlay extends StatelessWidget {
  const _UploadOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                color: Color(0xFF5B4FCF),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Uploading video…',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Do not close the app or switch screens.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscardDialog extends StatelessWidget {
  const _DiscardDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Discard upload?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
      ),
      content: const Text(
        'You have unsaved changes. Going back will clear your form.',
        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEEEEEE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Keep editing',
              style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final String title;
  final VoidCallback onDashboard;
  final VoidCallback onUploadAnother;

  const _SuccessSheet({
    required this.title,
    required this.onDashboard,
    required this.onUploadAnother,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF2BB5A0), size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload successful!',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 6),
          Text(
            '"$title" is now available to students.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4FCF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Go to dashboard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onUploadAnother,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEEEEEE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Upload another',
                style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    )
  )
    );
  }
}

class _ErrorSheet extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _ErrorSheet({
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  String _friendlyMessage(String raw) {
    if (raw.toLowerCase().contains('storage')) {
      return 'Storage Error: ${raw.replaceAll('Exception:', '').trim()}';
    }
    if (raw.toLowerCase().contains('database') || raw.toLowerCase().contains('postgrest')) {
      return 'Database Error: ${raw.replaceAll('Exception:', '').trim()}';
    }
    if (raw.contains('SocketException') || raw.contains('network')) {
      return 'Network Error: Please check your connection.';
    }
    return 'Upload failed: $raw';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.close_rounded, color: Color(0xFFE53935), size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload failed',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 6),
          Text(
            _friendlyMessage(message),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4FCF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Try again',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEEEEEE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      ))
    );
  }
}

class _SkeletonField extends StatelessWidget {
  const _SkeletonField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _ErrorField extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorField(this.message, {this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFE53935)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFE53935), fontWeight: FontWeight.w500),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFE53935)),
              onPressed: onRetry,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
