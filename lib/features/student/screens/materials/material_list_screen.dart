import 'package:flutter/material.dart';

import '../../../../models/study_material_model.dart';
import '../../../../services/material_service.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({
    super.key,
    required this.subjectId,
    required this.chapterId,
  });

  final String subjectId;
  final String chapterId;

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final MaterialService _materialService = MaterialService();
  late Future<List<StudyMaterialModel>> _materialsFuture;

  @override
  void initState() {
    super.initState();
    _materialsFuture = _materialService.fetchMaterialsBySubjectAndChapter(
      subjectId: widget.subjectId,
      chapterId: widget.chapterId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chapterId} Materials'),
      ),
      body: FutureBuilder<List<StudyMaterialModel>>(
        future: _materialsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading materials: ${snapshot.error}'),
            );
          }

          final materials = snapshot.data ?? [];

          if (materials.isEmpty) {
            return const Center(
              child: Text('No materials available for this chapter.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final material = materials[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(material.title),
                  subtitle: Text(
                    material.description?.isNotEmpty == true
                        ? material.description!
                        : 'Uploaded on ${material.uploadedAt.toLocal()}',
                  ),
                  onTap: () async {
                    final url = await _materialService.getPublicUrl(
                      material.storagePath,
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Open file URL: $url')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
