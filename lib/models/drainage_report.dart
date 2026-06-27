import 'package:intl/intl.dart';

class DrainageReport {
  final String id;
  final String displayId;
  final String issue;
  final String location;
  final String status;
  final String submittedBy;
  final String contactNo;
  final String description;
  final String imageUrl;
  final DateTime? createdAt;

  const DrainageReport({
    required this.id,
    required this.displayId,
    required this.issue,
    required this.location,
    required this.status,
    required this.submittedBy,
    required this.contactNo,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
  });

  factory DrainageReport.fromMap(Map<String, dynamic> data) {
    final id = '${data['id'] ?? ''}';
    final reportNo = data['report_no'];
    final createdValue = data['date_submitted'] ?? data['created_at'];
    final createdAt = createdValue == null
        ? null
        : DateTime.tryParse('$createdValue');

    return DrainageReport(
      id: id,
      displayId: reportNo == null
          ? id.substring(0, id.length < 8 ? id.length : 8)
          : '#$reportNo',
      issue: '${data['issue'] ?? data['issue_type'] ?? 'Drainage Issue'}',
      location: '${data['location'] ?? ''}',
      status: '${data['status'] ?? 'In Progress'}',
      submittedBy: '${data['submitted_by'] ?? 'Anonymous'}',
      contactNo: '${data['contact_no'] ?? ''}',
      description: '${data['description'] ?? ''}',
      imageUrl: '${data['image_url'] ?? ''}',
      createdAt: createdAt,
    );
  }

  String get formattedDate {
    if (createdAt == null) return 'N/A';
    return DateFormat('MMM d, yyyy  h:mm a').format(createdAt!.toLocal());
  }
}
