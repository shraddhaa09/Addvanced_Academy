import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/material_service.dart';

final materialServiceProvider = Provider<MaterialService>((ref) {
  return MaterialService(Supabase.instance.client);
});

class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  ConsumerState<UploadMaterialScreen> createState() =>
      _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _subjectId;
  String? _chapterId;
  String _subjectLabel = 'Mathematics';
  String _chapterLabel = 'Calculus II';
  String _materialType = 'pdf';
  bool _visibleToStudents = true;
  bool _isUploading = false;
  PlatformFile? _pickedFile;

  final _subjects = const [
    {'id': 'sub-1', 'label': 'Mathematics'},
    {'id': 'sub-2', 'label': 'Physics'},
  ];

  final _chapters = const [
    {'id': 'ch-1', 'label': 'Calculus I'},
    {'id': 'ch-2', 'label': 'Calculus II'},
  ];

  final _types = const [
    {'id': 'pdf', 'label': 'PDF Document'},
    {'id': 'doc', 'label': 'DOC File'},
    {'id': 'img', 'label': 'Image'},
  ];

  @override
  void initState() {
    super.initState();
    _subjectId = _subjects.first['id'];
    _chapterId = _chapters.first['id'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() => _pickedFile = result.files.single);
  }

  Future<void> _uploadMaterial() async {
    if (_pickedFile?.path == null) return;
    if (_subjectId == null || _chapterId == null) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a material title')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final service = ref.read(materialServiceProvider);
      final file = File(_pickedFile!.path!);
      final facultyId = Supabase.instance.client.auth.currentUser?.id ?? '';

      final storagePath = await service.uploadMaterialFile(
        file: file,
        facultyId: facultyId,
        subjectId: _subjectId!,
        chapterId: _chapterId!,
      );

      await service.createStudyMaterial(
        facultyId: facultyId,
        subjectId: _subjectId!,
        chapterId: _chapterId!,
        title: _titleController.text.trim(),
        storagePath: storagePath,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        materialType: _materialType,
        isVisible: _visibleToStudents,
        fileSizeKb: (_pickedFile!.size / 1024).round(),
      );

      setState(() => _isUploading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material uploaded successfully')),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _pickSubject() async {
    final r = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (_) => _PickerSheet(items: _subjects),
    );
    if (r != null) {
      setState(() {
        _subjectId = r['id'];
        _subjectLabel = r['label'] ?? _subjectLabel;
      });
    }
  }

  Future<void> _pickChapter() async {
    final r = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (_) => _PickerSheet(items: _chapters),
    );
    if (r != null) {
      setState(() {
        _chapterId = r['id'];
        _chapterLabel = r['label'] ?? _chapterLabel;
      });
    }
  }

  Future<void> _pickType() async {
    final r = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (_) => _PickerSheet(items: _types),
    );
    if (r != null) {
      setState(() => _materialType = r['id'] ?? _materialType);
    }
  }

  String _formatBytes(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B5FEF);
    const bg = Color(0xFFF4F5F9);
    const dark = Color(0xFF1A1A2E);
    const grey = Color(0xFF6B7280);

    final materialTypeLabel =
        _types.firstWhere((e) => e['id'] == _materialType)['label'] ?? '';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.menu_rounded, color: dark),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Study Material',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Upload and manage learning resources',
              style: TextStyle(color: grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.school_rounded, color: primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. Aris Thorne',
                        style: TextStyle(
                          color: dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mathematics • 42 Materials',
                        style: TextStyle(color: grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _UnderlineDropdown(
                  label: 'SUBJECT',
                  value: _subjectLabel,
                  onTap: _pickSubject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _UnderlineDropdown(
                  label: 'CHAPTER',
                  value: _chapterLabel,
                  onTap: _pickChapter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _FieldLabel(label: 'MATERIAL TITLE'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'e.g. Advanced Integration Techniques',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel(label: 'DESCRIPTION'),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Briefly describe the resource content…',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel(label: 'MATERIAL TYPE'),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickType,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      materialTypeLabel,
                      style: const TextStyle(
                        color: dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    color: grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            decoration: BoxDecoration(
              border: Border.all(color: primary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.file_upload_outlined, color: primary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  width: 130,
                  child: ElevatedButton(
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Select File',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Max size 25MB • PDF, DOC, IMG',
                  style: TextStyle(color: grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_pickedFile != null) ...[
            const SizedBox(height: 12),
            _SelectedFileRow(
              fileName: _pickedFile!.name,
              fileSize: _formatBytes(_pickedFile!.size),
              onRemove: _isUploading ? null : () => setState(() => _pickedFile = null),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white,
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visible to Students',
                        style: TextStyle(
                          color: dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Allow students to view and download',
                        style: TextStyle(color: grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _visibleToStudents,
                  activeColor: primary,
                  onChanged: (v) => setState(() => _visibleToStudents = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Selected type: $materialTypeLabel',
            style: const TextStyle(color: grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadMaterial,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Upload Material',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: dark,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      letterSpacing: 0.4,
      fontWeight: FontWeight.w700,
      color: Color(0xFF6B7280),
    ),
  );
}

class _UnderlineDropdown extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _UnderlineDropdown({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label: label),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_double_arrow_down_rounded,
                color: Color(0xFF6B7280),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _PickerSheet extends StatelessWidget {
  final List<Map<String, String>> items;

  const _PickerSheet({required this.items});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      children: items
          .map(
            (e) => ListTile(
          title: Text(e['label'] ?? ''),
          onTap: () => Navigator.pop(context, e),
        ),
      )
          .toList(),
    ),
  );
}

class _SelectedFileRow extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final VoidCallback? onRemove;

  const _SelectedFileRow({
    required this.fileName,
    required this.fileSize,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fileSize,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onRemove,
          child: const Icon(
            Icons.close_rounded,
            color: Color(0xFFEF4444),
            size: 18,
          ),
        ),
      ],
    ),
  );
}