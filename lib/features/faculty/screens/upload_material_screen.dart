import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/study_material_model.dart';
import '../../../services/material_service.dart';

final materialServiceProvider = Provider<MaterialService>((ref) {
  return MaterialService(Supabase.instance.client);
});

class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  ConsumerState<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedSubject = 'Mathematics';
  String _selectedChapter = 'Calculus II';
  String _selectedMaterialType = 'PDF Document';
  bool _visibleToStudents = true;
  bool _isUploading = false;
  PlatformFile? _pickedFile;
  String? _uploadedUrl;

  final List<String> _subjects = const ['Physics', 'Chemistry', 'Mathematics', 'Biology'];
  final List<String> _chapters = const ['Calculus I', 'Calculus II', 'Matrices', 'Differentiation'];
  final List<String> _materialTypes = const ['PDF Document', 'DOC File', 'Image'];

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
    setState(() {
      _pickedFile = result.files.single;
      _uploadedUrl = null;
    });
  }

  Future<void> _uploadMaterial() async {
    if (_pickedFile?.path == null) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a material title')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final service = ref.read(materialServiceProvider);
      final file = File(_pickedFile!.path!);
      final facultyId = Supabase.instance.client.auth.currentUser?.id ?? '';

      final url = await service.uploadMaterialFile(
        file: file,
        subject: _selectedSubject,
        chapter: _selectedChapter,
        facultyId: facultyId,
      );

      final material = await service.createStudyMaterial(
        facultyId: facultyId,
        subject: _selectedSubject,
        chapter: _selectedChapter,
        title: _titleController.text.trim(),
        fileUrl: url,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        materialType: _selectedMaterialType,
        visibleToStudents: _visibleToStudents,
        fileSize: _formatBytes(_pickedFile!.size),
      );

      setState(() {
        _uploadedUrl = material.fileUrl;
        _isUploading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material uploaded successfully')));
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B5FEF);
    const bg = Color(0xFFF4F5F9);
    const dark = Color(0xFF1A1A2E);
    const grey = Color(0xFF6B7280);

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Study Material',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Upload and manage learning resources',
              style: TextStyle(
                color: grey,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dr. Aris Thorne',
                        style: TextStyle(
                          color: dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          _SmallPill(label: 'Mathematics'),
                          SizedBox(width: 8),
                          Text('•', style: TextStyle(color: grey)),
                          SizedBox(width: 8),
                          Text(
                            '42 Materials',
                            style: TextStyle(
                              color: grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _UnderlineDropdown(
                        label: 'SUBJECT',
                        value: _selectedSubject,
                        doubleChevron: true,
                        onTap: () async {
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => _SimplePickerSheet(title: 'Select Subject', items: _subjects, selected: _selectedSubject),
                          );
                          if (result != null) setState(() => _selectedSubject = result);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UnderlineDropdown(
                        label: 'CHAPTER',
                        value: _selectedChapter,
                        doubleChevron: true,
                        onTap: () async {
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => _SimplePickerSheet(title: 'Select Chapter', items: _chapters, selected: _selectedChapter),
                          );
                          if (result != null) setState(() => _selectedChapter = result);
                        },
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
                    border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5E7EB))),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                ),
                const SizedBox(height: 14),
                const _FieldLabel(label: 'MATERIAL TYPE'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final result = await showModalBottomSheet<String>(
                      context: context,
                      builder: (context) => _SimplePickerSheet(title: 'Select Material Type', items: _materialTypes, selected: _selectedMaterialType),
                    );
                    if (result != null) setState(() => _selectedMaterialType = result);
                  },
                  borderRadius: BorderRadius.circular(8),
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
                            _selectedMaterialType,
                            style: const TextStyle(
                              color: dark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_double_arrow_down_rounded, color: grey),
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
                          onPressed: _isUploading ? null : _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text('Select File', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Max size 25MB • PDF, DOC, IMG', style: TextStyle(color: grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (_pickedFile != null) ...[
                  const SizedBox(height: 12),
                  _SelectedFileRow(
                    fileName: _pickedFile!.name,
                    fileSize: _formatBytes(_pickedFile!.size),
                    onRemove: _isUploading
                        ? null
                        : () {
                      setState(() {
                        _pickedFile = null;
                        _uploadedUrl = null;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visible to Students',
                              style: TextStyle(color: dark, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Allow students to view and download',
                              style: TextStyle(color: grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(value: _visibleToStudents, activeColor: primary, onChanged: (value) => setState(() => _visibleToStudents = value)),
                    ],
                  ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Upload Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: dark, fontWeight: FontWeight.w400, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.4)));
  }
}

class _UnderlineDropdown extends StatelessWidget {
  final String label;
  final String value;
  final bool doubleChevron;
  final VoidCallback onTap;
  const _UnderlineDropdown({required this.label, required this.value, required this.doubleChevron, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
            child: Row(children: [Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600))), Icon(doubleChevron ? Icons.keyboard_double_arrow_down_rounded : Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 20)]),
          ),
        ),
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  const _SmallPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF5B5FEF), borderRadius: BorderRadius.circular(999)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)));
  }
}

class _SimplePickerSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selected;
  const _SimplePickerSheet({required this.title, required this.items, required this.selected});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...items.map((item) => ListTile(title: Text(item), trailing: item == selected ? const Icon(Icons.check, color: Color(0xFF5B5FEF)) : null, onTap: () => Navigator.pop(context, item))),
        ],
      ),
    );
  }
}

class _SelectedFileRow extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final VoidCallback? onRemove;
  const _SelectedFileRow({required this.fileName, required this.fileSize, this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))]),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(fileName, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(fileSize, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12))]),
          ),
          InkWell(onTap: onRemove, child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18)),
        ],
      ),
    );
  }
}