import 'package:intl/intl.dart';

class IssueLocation {
  final String label;
  final double latitude;
  final double longitude;

  const IssueLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

class DrainageReport {
  final String id;
  final String displayId;
  final String title;
  final String location;
  final String status;
  final String submittedBy;
  final String contactNo;
  final String description;
  final String imageUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  const DrainageReport({
    required this.id,
    required this.displayId,
    required this.title,
    required this.location,
    required this.status,
    required this.submittedBy,
    required this.contactNo,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  String get issue => title;

  String get formattedDate {
    if (createdAt == null) return 'N/A';
    return DateFormat('MMM d, yyyy  h:mm a').format(createdAt!.toLocal());
  }

  factory DrainageReport.fromSupabase(Map<String, dynamic> data) {
    final createdAtValue = data['created_at'];
    final id = '${data['id']}';
    final user = data['users'];
    final userProfile = user is Map ? user : const <String, dynamic>{};

    return DrainageReport(
      id: id,
      displayId: 'DR-${id.substring(0, 8).toUpperCase()}',
      title: '${data['title'] ?? 'Drainage Issue'}',
      location: '${data['location_label'] ?? 'Pinned location'}',
      status: '${data['status'] ?? 'Pending'}',
      submittedBy: '${userProfile['fullname'] ?? ''}',
      contactNo: '${userProfile['phone'] ?? ''}',
      description: '${data['description'] ?? ''}',
      imageUrl: '${data['image_url'] ?? ''}',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt: createdAtValue == null
          ? null
          : DateTime.tryParse('$createdAtValue'),
    );
  }
}
