import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/faculty_upload_model.dart';

class RecentUploadTile extends StatelessWidget {
  final FacultyUploadModel upload;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int? viewCount;

  const RecentUploadTile({
    super.key,
    required this.upload,
    this.onEdit,
    this.onDelete,
    this.viewCount,
  });

  bool get _isVideo => upload.contentType.toLowerCase() == 'video';

  String get _typeLabel {
    switch (upload.contentType.toLowerCase()) {
      case 'video':
        return 'VIDEO';
      case 'pdf':
        return 'PDF';
      case 'image':
        return 'IMAGE';
      case 'doc':
      case 'docx':
        return 'DOC';
      default:
        return 'FILE';
    }
  }

  IconData get _icon =>
      _isVideo ? Icons.play_circle_outline : Icons.insert_drive_file_outlined;

  Color get _accentColor =>
      _isVideo ? const Color(0xFF5B4FCF) : const Color(0xFF1E8C6E);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_icon, color: _accentColor),
        ),

        title: Text(
          upload.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1F2937),
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${upload.subject} • ${upload.chapter}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5B4FCF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                upload.uploadedAt != null
                    ? timeago.format(upload.uploadedAt!)
                    : 'Just now',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Chip(
                    label: upload.isVisible ? "VISIBLE" : "HIDDEN",
                    color:
                        upload.isVisible ? Colors.green : Colors.orange,
                  ),
                  _Chip(
                    label: _typeLabel,
                    color: Colors.grey,
                  ),
                  if (viewCount != null)
                    _ViewChip(count: viewCount!),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          onSelected: (val) {
            if (val == 'edit') onEdit?.call();
            if (val == 'delete') onDelete?.call();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Edit Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ViewChip extends StatelessWidget {
  final int count;

  const _ViewChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4FCF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_outlined,
              size: 12, color: Color(0xFF5B4FCF)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5B4FCF),
            ),
          ),
        ],
      ),
    );
  }
}
