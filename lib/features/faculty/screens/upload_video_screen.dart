import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/chapter_model.dart';
import '../../../models/subject_model.dart';
import '../../../providers/faculty_providers.dart';

class UploadVideoScreen extends ConsumerStatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  ConsumerState<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends ConsumerState<UploadVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  SubjectModel? _selectedSubject;
  ChapterModel? _selectedChapter;
  bool _isVisible = true;
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate() || _selectedSubject == null || _selectedChapter == null || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select a video')),
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

      final videoService = ref.read(videoServiceProvider);

      // Upload file
      final storagePath = await videoService.uploadVideoFile(
        file: _selectedFile!,
        facultyId: facultyId,
        subjectId: _selectedSubject!.id,
        chapterId: _selectedChapter!.id,
      );

      // Save record
      await videoService.createVideoLecture(
        facultyId: facultyId,
        subjectId: _selectedSubject!.id,
        chapterId: _selectedChapter!.id,
        title: _titleController.text.trim(),
        storagePath: storagePath,
        description: _descriptionController.text.trim(),
        durationSec: int.tryParse(_durationController.text.trim()),
        fileSizeKb: (_selectedFile!.lengthSync() / 1024).round(),
        isVisible: _isVisible,
      );

      // Refresh recent uploads
      ref.invalidate(recentFacultyUploadsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
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
        title: const Text('Upload Video Lecture'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B4FCF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video File Selection
                    GestureDetector(
                      onTap: _pickVideo,
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
                                  Icon(Icons.video_call, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to select video',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'MP4, MOV (Max 500MB)',
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
                                    onPressed: _pickVideo,
                                    child: const Text('Change File'),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Video Title'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration('Description (Optional)'),
                      maxLines: 3,
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
                            _selectedChapter = null; // Reset chapter when subject changes
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

                    TextFormField(
                      controller: _durationController,
                      decoration: _inputDecoration('Duration (Seconds)'),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                          return 'Must be a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Visible to Students'),
                      subtitle: const Text('Publish immediately after upload'),
                      value: _isVisible,
                      onChanged: (val) => setState(() => _isVisible = val),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: const Color(0xFF5B4FCF),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _upload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4FCF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Upload Video',
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
        borderSide: const BorderSide(color: Color(0xFF5B4FCF), width: 2),
      ),
    );
  }
}