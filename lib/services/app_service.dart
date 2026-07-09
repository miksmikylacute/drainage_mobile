import 'dart:io';

import '../models/drainage_report.dart';

class AppUser {
  final String id;
  final String email;
  final Map<String, dynamic> userMetadata;

  const AppUser({
    required this.id,
    required this.email,
    this.userMetadata = const {},
  });

  AppUser copyWith({String? email, Map<String, dynamic>? userMetadata}) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      userMetadata: userMetadata ?? this.userMetadata,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });
}

class AppService {
  static AppUser? _currentUser;

  static AppUser? get currentUser => _currentUser;

  static bool get isSignedIn => _currentUser != null;

  static String get residentName {
    final metadata = currentUser?.userMetadata ?? {};
    return '${metadata['name'] ?? currentUser?.email ?? 'Resident'}';
  }

  static String get residentContact {
    final metadata = currentUser?.userMetadata ?? {};
    return '${metadata['contact_no'] ?? metadata['contact'] ?? ''}';
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    _currentUser = AppUser(
      id: 'frontend-preview-user',
      email: email.trim(),
      userMetadata: {'name': email.trim(), 'contact_no': ''},
    );
  }

  static Future<void> signUp({
    required String name,
    required String contactNo,
    required String email,
    required String password,
  }) async {
    throw Exception('Backend integration is not connected yet.');
  }

  static Future<void> signOut() async {
    _currentUser = null;
  }

  static Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    _currentUser = user.copyWith(
      email: email,
      userMetadata: {...user.userMetadata, 'name': name, 'contact_no': phone},
    );
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) throw Exception('No authenticated user.');
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw Exception('Password fields are required.');
    }
  }

  static Future<DrainageReport> submitReport({
    required File photo,
    required String location,
    required String description,
  }) async {
    throw Exception('Backend integration is not connected yet.');
  }

  static Future<List<DrainageReport>> fetchMyReports() async {
    return [];
  }

  static Future<List<AppNotification>> fetchNotifications() async {
    return [];
  }

  static Future<void> markNotificationAsRead(String id) async {
    throw Exception('Backend integration is not connected yet.');
  }
}
