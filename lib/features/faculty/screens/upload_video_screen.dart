import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/video_service.dart';
import '../../../models/video_lecture_model.dart';
import '../widgets/upload_progress_widget.dart';

final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService(Supabase.instance.client);
});

class UploadVideoScreen extends ConsumerStatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  ConsumerState<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends ConsumerState<UploadVideoScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedSubject = 'Mathematics';
  String _selectedChapter = 'Calculus II';
  bool _visibleToStudents = true;
  bool _isUploading = false;
  double _progress = 0;
  PlatformFile? _pickedFile;
  String? _uploadedUrl;

  final List<String> _subjects = const ['Physics', 'Chemistry', 'Mathematics', 'Biology'];
  final List<String> _chapters = const ['Calculus I', 'Calculus II', 'Matrices', 'Differentiation'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'mkv', 'avi'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _pickedFile = result.files.single;
      _uploadedUrl = null;
      _progress = 0;
    });
  }

  Future<void> _uploadVideo() async {
    if (_pickedFile?.path == null) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a video title')));
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0.1;
    });

    try {
      final service = ref.read(videoServiceProvider);
      final file = File(_pickedFile!.path!);
      final facultyId = Supabase.instance.client.auth.currentUser?.id ?? '';

      setState(() => _progress = 0.35);
      final url = await service.uploadVideoFile(
        file: file,
        subject: _selectedSubject,
        facultyId: facultyId,
      );

      setState(() => _progress = 0.75);
      final lecture = await service.createVideoLecture(
        facultyId: facultyId,
        subject: _selectedSubject,
        title: _titleController.text.trim(),
        videoUrl: url,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        chapter: _selectedChapter,
        visibleToStudents: _visibleToStudents,
        duration: _durationController.text.trim().isEmpty ? null : _durationController.text.trim(),
      );

      setState(() {
        _uploadedUrl = lecture.videoUrl;
        _progress = 1;
        _isUploading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video uploaded successfully')));
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
          icon: const Icon(Icons.arrow_back_rounded, color: primary),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Video Lecture',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Upload and manage educational videos',
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
        padding: const EdgeInsets.all(16),
        children: [
          _CardShell(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.school_rounded, color: primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dr. Aris Thorne',
                        style: TextStyle(
                          color: dark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Pill(label: 'Mathematics', background: const Color(0xFFFFF3E0), textColor: const Color(0xFFF59E0B)),
                          const _CounterChip(icon: Icons.ondemand_video_rounded, label: '24 Videos'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Video Details',
                  style: TextStyle(color: dark, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DropdownField(
                        label: 'SUBJECT',
                        value: _selectedSubject,
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
                      child: _DropdownField(
                        label: 'CHAPTER',
                        value: _selectedChapter,
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
                const _FieldLabel(label: 'VIDEO TITLE *'),
                const SizedBox(height: 6),
                TextField(controller: _titleController, decoration: _inputDecoration('Enter descriptive title')),
                const SizedBox(height: 14),
                const _FieldLabel(label: 'DESCRIPTION'),
                const SizedBox(height: 6),
                TextField(controller: _descriptionController, minLines: 3, maxLines: 4, decoration: _inputDecoration('Add lecture summary…')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: _isUploading ? null : _pickVideo,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
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
                          child: const Icon(Icons.cloud_upload_rounded, color: primary),
                        ),
                        const SizedBox(height: 10),
                        const Text('Tap to select video', style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('MP4, MOV up to 500MB', style: TextStyle(color: grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                if (_pickedFile != null) ...[
                  const SizedBox(height: 14),
                  _SelectedFileRow(
                    fileName: _pickedFile!.name,
                    fileSize: _formatBytes(_pickedFile!.size),
                    showRemove: !_isUploading,
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
                if (_isUploading) ...[
                  const SizedBox(height: 10),
                  UploadProgressWidget(progress: _progress, rightText: '${(_progress * 100).toInt()}%'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CardShell(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Colors.grey, size: 20),
                    const SizedBox(width: 10),
                    const Text('Duration', style: TextStyle(color: dark, fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _durationController,
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '45:20', hintStyle: TextStyle(color: primary, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, color: Colors.grey, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Visible to Students', style: TextStyle(color: dark, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    Switch(value: _visibleToStudents, activeColor: primary, onChanged: (value) => setState(() => _visibleToStudents = value)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Upload Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cancel', style: TextStyle(color: grey, fontWeight: FontWeight.w400, fontSize: 15)),
            ),
          ),
          if (_uploadedUrl != null) ...[
            const SizedBox(height: 14),
            Text('Uploaded URL: $_uploadedUrl', style: const TextStyle(fontSize: 12, color: grey)),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF5B5FEF))),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 11, letterSpacing: 0.4, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)));
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DropdownField({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Row(children: [Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600))), const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280))]),
          ),
        ),
      ],
    );
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

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  const _Pill({required this.label, required this.background, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _CounterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CounterChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]);
  }
}

class _SelectedFileRow extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final bool showRemove;
  final VoidCallback? onRemove;
  const _SelectedFileRow({required this.fileName, required this.fileSize, required this.showRemove, this.onRemove});
  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF1A1A2E);
    return Row(
      children: [
        const Icon(Icons.video_file_rounded, color: Color(0xFF5B5FEF)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: dark)),
              const SizedBox(height: 2),
              Text(fileSize, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        if (showRemove)
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
          ),
      ],
    );
  }
}