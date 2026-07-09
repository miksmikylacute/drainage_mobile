import 'package:intl/intl.dart';

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
}
