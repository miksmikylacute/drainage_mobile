import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  static SupabaseClient get _client => Supabase.instance.client;

  static AppUser? get currentUser => _currentUser;

  static bool get isSignedIn => _currentUser != null;

  static String get residentName {
    final metadata = currentUser?.userMetadata ?? {};
    return '${metadata['fullname'] ?? metadata['name'] ?? currentUser?.email ?? 'Resident'}';
  }

  static String get residentContact {
    final metadata = currentUser?.userMetadata ?? {};
    return '${metadata['phone'] ?? metadata['contact_no'] ?? metadata['contact'] ?? ''}';
  }

  static String get avatarUrl {
    final metadata = currentUser?.userMetadata ?? {};
    return '${metadata['avatar_url'] ?? ''}';
  }

  static String friendlyAuthError(Object error, {required String fallback}) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'No matching resident account was found. Please check your email and password.';
    }

    if (message.contains('user already registered') ||
        message.contains('already been registered') ||
        message.contains('already exists')) {
      return 'This email is already registered. Please login or use another email.';
    }

    if (message.contains('admin accounts cannot use') ||
        message.contains('resident accounts cannot access')) {
      return 'This account is not allowed to use this app.';
    }

    if (message.contains('disabled')) {
      return 'This account is disabled. Please contact the administrator.';
    }

    if (message.contains('unable to load') ||
        message.contains('contains 0 rows') ||
        message.contains('no rows')) {
      return 'Your account profile was not found. Please contact the administrator.';
    }

    if (message.contains('password should be') ||
        message.contains('weak password')) {
      return 'Please use a stronger password.';
    }

    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    return fallback;
  }

  static Future<void> initializeSession() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _currentUser = null;
      return;
    }

    await _loadResidentProfile(user.id);
  }

  static Future<void> refreshCurrentUser() async {
    final userId = _currentUser?.id ?? _client.auth.currentUser?.id;
    if (userId == null) return;

    await _loadResidentProfile(userId);
  }

  static Future<void> _loadResidentProfile(String userId) async {
    final profile = await _client
        .from('users')
        .select('id,email,fullname,phone,avatar_url,role,status')
        .eq('id', userId)
        .single();

    final role = '${profile['role']}';
    final status = '${profile['status']}';

    if (role != 'resident') {
      await _client.auth.signOut();
      _currentUser = null;
      throw Exception('Admin accounts cannot use the mobile reporting app.');
    }

    if (status != 'Active') {
      await _client.auth.signOut();
      _currentUser = null;
      throw Exception('This resident account is disabled.');
    }

    _currentUser = AppUser(
      id: '${profile['id']}',
      email: '${profile['email']}',
      userMetadata: {
        'fullname': profile['fullname'],
        'name': profile['fullname'],
        'phone': profile['phone'] ?? '',
        'contact_no': profile['phone'] ?? '',
        'avatar_url': profile['avatar_url'] ?? '',
        'role': role,
        'status': status,
      },
    );
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Unable to sign in.');
    }

    await _loadResidentProfile(user.id);
  }

  static Future<void> signUp({
    required String name,
    required String contactNo,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'role': 'resident',
        'fullname': name.trim(),
        'phone': contactNo.trim(),
      },
    );

    final user = response.user;
    if (user != null && response.session != null) {
      await _loadResidentProfile(user.id);
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
    _currentUser = null;
  }

  static Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
    XFile? avatar,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    if (email.trim() != user.email) {
      await _client.auth.updateUser(UserAttributes(email: email.trim()));
    }

    final avatarUrl = avatar == null
        ? AppService.avatarUrl
        : await _uploadAvatar(avatar);

    await _client
        .from('users')
        .update({
          'email': email.trim(),
          'fullname': name.trim(),
          'phone': phone.trim(),
          'avatar_url': avatarUrl,
        })
        .eq('id', user.id);

    _currentUser = user.copyWith(
      email: email.trim(),
      userMetadata: {
        ...user.userMetadata,
        'fullname': name.trim(),
        'name': name.trim(),
        'phone': phone.trim(),
        'contact_no': phone.trim(),
        'avatar_url': avatarUrl,
      },
    );
  }

  static Future<String> _uploadAvatar(XFile avatar) async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    final extension = avatar.name.split('.').last.toLowerCase();
    final safeExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
    final path =
        '${user.id}/avatar-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final bytes = await avatar.readAsBytes();

    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _avatarContentType(safeExtension),
          ),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  static String _avatarContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) throw Exception('No authenticated user.');
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw Exception('Password fields are required.');
    }

    final email = _currentUser!.email;
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
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
