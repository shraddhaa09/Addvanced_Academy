import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/faculty_providers.dart';
import '../../../models/faculty_upload_model.dart';

class EditUploadScreen extends ConsumerStatefulWidget {
  final FacultyUploadModel upload;

  const EditUploadScreen({super.key, required this.upload});

  @override
  ConsumerState<EditUploadScreen> createState() => _EditUploadScreenState();
}

class _EditUploadScreenState extends ConsumerState<EditUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isVisible;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.upload.title);
    _descriptionController = TextEditingController(text: widget.upload.description);
    _isVisible = widget.upload.isVisible;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(facultyUploadServiceProvider).updateUpload(
        id: widget.upload.id,
        contentType: widget.upload.contentType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isVisible: _isVisible,
      );

      // Invalidate the list and stats to ensure UI updates
      ref.invalidate(recentFacultyUploadsProvider(null));
      ref.invalidate(facultyStatsProvider);

      // Also invalidate view counts in case visibility/stats changed
      final facultyIdAsync = ref.read(currentFacultyIdProvider);
      final facultyId = facultyIdAsync.value;

      if (facultyId != null) {
        ref.invalidate(contentViewCountsProvider(facultyId));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Edit Upload'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
          else
            TextButton(
              onPressed: _save,
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B4FCF))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editing ${widget.upload.contentType == 'video' ? 'Video' : 'Material'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Title'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.subject, size: 20, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Text('Subject: ', style: TextStyle(color: Colors.grey[600])),
                        Text(widget.upload.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.folder_open, size: 20, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Text('Chapter: ', style: TextStyle(color: Colors.grey[600])),
                        Text(widget.upload.chapter, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                title: const Text('Visible to Students'),
                subtitle: const Text('Publish this content to the student app'),
                value: _isVisible,
                onChanged: (val) => setState(() => _isVisible = val),
                activeColor: const Color(0xFF5B4FCF),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5B4FCF), width: 2),
      ),
    );
  }
}
