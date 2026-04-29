import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/faculty_upload_model.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FacultyMaterialViewerScreen extends StatefulWidget {
  final FacultyUploadModel upload;
  const FacultyMaterialViewerScreen({super.key, required this.upload});

  @override
  State<FacultyMaterialViewerScreen> createState() => _FacultyMaterialViewerScreenState();
}

class _FacultyMaterialViewerScreenState extends State<FacultyMaterialViewerScreen> {
  String? _localPdfPath;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final url = Supabase.instance.client.storage
        .from('study-materials')
        .getPublicUrl(widget.upload.storagePath);

    final ext = widget.upload.storagePath.split('.').last.toLowerCase();

    if (ext == 'pdf') {
      await _downloadPdf(url);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_preview_${widget.upload.id}.pdf');
        await file.writeAsBytes(bytes);
        if (mounted) setState(() {
          _localPdfPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = Supabase.instance.client.storage
        .from('study-materials')
        .getPublicUrl(widget.upload.storagePath);

    final ext = widget.upload.storagePath.split('.').last.toLowerCase();
    final isPdf = ext == 'pdf';
    final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.upload.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(widget.upload.subject, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Color(0xFF1E8C6E))
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Error: $_error', textAlign: TextAlign.center),
                  )
                : isPdf
                    ? PDFView(
                        filePath: _localPdfPath,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: false,
                        pageFling: false,
                      )
                    : isImage
                        ? InteractiveViewer(
                            child: CachedNetworkImage(
                              imageUrl: url,
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text('No preview available for $ext files'),
                              const SizedBox(height: 8),
                              const Text('Please download the file to view it.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
      ),
    );
  }
}
