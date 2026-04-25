import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/chapter_model.dart';
import '../../../models/subject_model.dart';
import '../../../providers/faculty_providers.dart';

class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  ConsumerState<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  SubjectModel? _selectedSubject;
  ChapterModel? _selectedChapter;
  String _materialType = 'pdf';
  bool _isVisible = true;
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate() || _selectedSubject == null || _selectedChapter == null || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select a file')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final facultyId = await ref.read(currentFacultyIdProvider.future);
      if (facultyId == null) {
        throw Exception('Could not determine faculty ID');
      }

      final materialService = ref.read(materialServiceProvider);

      // Upload file
      final storagePath = await materialService.uploadMaterialFile(
        file: _selectedFile!,
        facultyId: facultyId,
        subjectId: _selectedSubject!.id,
        chapterId: _selectedChapter!.id,
      );

      // Save record
      await materialService.createStudyMaterial(
        facultyId: facultyId,
        subjectId: _selectedSubject!.id,
        chapterId: _selectedChapter!.id,
        title: _titleController.text.trim(),
        storagePath: storagePath,
        description: _descriptionController.text.trim(),
        materialType: _materialType,
        fileSizeKb: (_selectedFile!.lengthSync() / 1024).round(),
        isVisible: _isVisible,
      );

      // Refresh recent uploads
      ref.invalidate(recentFacultyUploadsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material uploaded successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final chaptersAsync = _selectedSubject != null 
        ? ref.watch(chaptersProvider(_selectedSubject!.id))
        : const AsyncValue.data(<ChapterModel>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        title: const Text('Upload Study Material'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E8C6E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Selection
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: _selectedFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to select file',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PDF, DOCX, IMG (Max 50MB)',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, size: 48, color: Color(0xFF1E8C6E)),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedFile!.path.split('/').last,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _pickFile,
                                    child: const Text('Change File', style: TextStyle(color: Color(0xFF1E8C6E))),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Material Title'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration('Description (Optional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _materialType,
                      decoration: _inputDecoration('Material Type'),
                      items: const [
                        DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                        DropdownMenuItem(value: 'doc', child: Text('Word Document')),
                        DropdownMenuItem(value: 'image', child: Text('Image')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) => setState(() => _materialType = val!),
                    ),
                    const SizedBox(height: 16),

                    subjectsAsync.when(
                      data: (subjects) => DropdownButtonFormField<SubjectModel>(
                        initialValue: _selectedSubject,
                        decoration: _inputDecoration('Select Subject'),
                        items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSubject = val;
                            _selectedChapter = null; // Reset chapter
                          });
                        },
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error loading subjects: $e'),
                    ),
                    const SizedBox(height: 16),

                    chaptersAsync.when(
                      data: (chapters) => DropdownButtonFormField<ChapterModel>(
                        initialValue: _selectedChapter,
                        decoration: _inputDecoration('Select Chapter'),
                        items: chapters.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                        onChanged: (val) => setState(() => _selectedChapter = val),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error loading chapters: $e'),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Visible to Students'),
                      subtitle: const Text('Publish immediately after upload'),
                      value: _isVisible,
                      onChanged: (val) => setState(() => _isVisible = val),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: const Color(0xFF1E8C6E),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _upload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8C6E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Upload Material',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
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
        borderSide: const BorderSide(color: Color(0xFF1E8C6E), width: 2),
      ),
    );
  }
}