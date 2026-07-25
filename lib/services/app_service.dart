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
  final String? reportId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    this.reportId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromSupabase(Map<String, dynamic> data) {
    final createdAtValue = data['created_at'];

    return AppNotification(
      id: '${data['id']}',
      reportId: data['report_id'] == null ? null : '${data['report_id']}',
      title: '${data['title'] ?? 'Notification'}',
      message: '${data['message'] ?? ''}',
      createdAt: DateTime.tryParse('${createdAtValue ?? ''}') ?? DateTime.now(),
      isRead: data['is_read'] == true,
    );
  }
}

class ResidentDashboardSummary {
  final List<DrainageReport> recentReports;
  final List<AppNotification> latestNotifications;
  final Map<String, int> statusCounts;
  final int unreadNotificationCount;

  const ResidentDashboardSummary({
    required this.recentReports,
    required this.latestNotifications,
    required this.statusCounts,
    required this.unreadNotificationCount,
  });

  int get totalReports =>
      statusCounts.values.fold(0, (sum, count) => sum + count);

  int countFor(String status) => statusCounts[status] ?? 0;
}

class ReportLog {
  final String id;
  final String reportId;
  final String? oldStatus;
  final String newStatus;
  final String remarks;
  final DateTime createdAt;

  const ReportLog({
    required this.id,
    required this.reportId,
    this.oldStatus,
    required this.newStatus,
    required this.remarks,
    required this.createdAt,
  });

  factory ReportLog.fromSupabase(Map<String, dynamic> data) {
    final createdAtValue = data['created_at'];

    return ReportLog(
      id: '${data['id']}',
      reportId: '${data['report_id']}',
      oldStatus: data['old_status'] == null ? null : '${data['old_status']}',
      newStatus: '${data['new_status'] ?? 'Pending'}',
      remarks: '${data['remarks'] ?? ''}',
      createdAt: DateTime.tryParse('${createdAtValue ?? ''}') ?? DateTime.now(),
    );
  }
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

  static Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('Email is required.');
    }

    await _client.auth.resetPasswordForEmail(email.trim());
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

  static String _reportMediaContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      case 'webm':
        return 'video/webm';
      default:
        return 'image/jpeg';
    }
  }

  static String _reportMediaExtension(XFile media) {
    final extension = media.name.split('.').last.toLowerCase();
    if ([
      'jpg',
      'jpeg',
      'png',
      'webp',
      'mp4',
      'mov',
      'm4v',
      'webm',
    ].contains(extension)) {
      return extension;
    }

    switch (media.mimeType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'video/quicktime':
        return 'mov';
      case 'video/x-m4v':
        return 'm4v';
      case 'video/webm':
        return 'webm';
      case 'video/mp4':
        return 'mp4';
      default:
        return 'jpg';
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
    required XFile media,
    required IssueLocation location,
    required String title,
    required String description,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    final mediaUrl = await _uploadReportMedia(media);
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();

    final reportData = await _client
        .from('reports')
        .insert({
          'user_id': user.id,
          'title': cleanTitle.length > 80
              ? cleanTitle.substring(0, 80)
              : cleanTitle,
          'description': cleanDescription,
          'image_url': mediaUrl,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'location_label': location.label,
          'status': 'Pending',
        })
        .select('*, users(fullname,phone,email,avatar_url)')
        .single();

    return DrainageReport.fromSupabase(reportData);
  }

  static Future<String> _uploadReportMedia(XFile media) async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    final safeExtension = _reportMediaExtension(media);
    final path =
        '${user.id}/report-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final bytes = await media.readAsBytes();

    await _client.storage
        .from('report-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _reportMediaContentType(safeExtension),
          ),
        );

    return _client.storage.from('report-photos').getPublicUrl(path);
  }

  static Future<List<DrainageReport>> fetchMyReports() async {
    final user = _currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('reports')
        .select('*, users(fullname,phone,email,avatar_url)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => DrainageReport.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  static Future<DrainageReport> fetchReportById(String reportId) async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    final row = await _client
        .from('reports')
        .select('*, users(fullname,phone,email,avatar_url)')
        .eq('id', reportId)
        .single();

    return DrainageReport.fromSupabase(row);
  }

  static Future<ResidentDashboardSummary>
  fetchResidentDashboardSummary() async {
    final user = _currentUser;
    if (user == null) {
      return const ResidentDashboardSummary(
        recentReports: [],
        latestNotifications: [],
        statusCounts: {},
        unreadNotificationCount: 0,
      );
    }

    final results = await Future.wait<dynamic>([
      fetchMyReports(),
      fetchNotifications(),
    ]);

    final reports = results[0] as List<DrainageReport>;
    final notifications = results[1] as List<AppNotification>;
    final statusCounts = <String, int>{
      'Pending': 0,
      'In Progress': 0,
      'Resolved': 0,
      'Rejected': 0,
    };

    for (final report in reports) {
      statusCounts[report.status] = (statusCounts[report.status] ?? 0) + 1;
    }

    return ResidentDashboardSummary(
      recentReports: reports.take(2).toList(),
      latestNotifications: notifications.take(2).toList(),
      statusCounts: statusCounts,
      unreadNotificationCount: notifications
          .where((notification) => !notification.isRead)
          .length,
    );
  }

  static Future<List<AppNotification>> fetchNotifications() async {
    final user = _currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('notifications')
        .select('id,user_id,report_id,title,message,is_read,created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => AppNotification.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ReportLog>> fetchReportLogs(String reportId) async {
    final user = _currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('report_logs')
        .select('id,report_id,old_status,new_status,remarks,created_at')
        .eq('report_id', reportId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => ReportLog.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markNotificationAsRead(String id) async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    await _client.rpc(
      'mark_notification_read',
      params: {'p_notification_id': id},
    );
  }

  static Future<void> markAllNotificationsAsRead() async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    await _client.rpc('mark_all_notifications_read');
  }

  static Future<int> fetchUnreadNotificationCount() async {
    final user = _currentUser;
    if (user == null) return 0;

    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    return (rows as List<dynamic>).length;
  }

  static RealtimeChannel? subscribeToNotificationChanges(
    void Function() onChange,
  ) {
    final user = _currentUser;
    if (user == null) return null;

    final channel = _client
        .channel('resident-notifications-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();

    return channel;
  }

  static RealtimeChannel? subscribeToMyReportChanges(void Function() onChange) {
    final user = _currentUser;
    if (user == null) return null;

    final channel = _client
        .channel('resident-reports-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reports',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();

    return channel;
  }

  static RealtimeChannel? subscribeToReportLogChanges(
    void Function() onChange,
  ) {
    final user = _currentUser;
    if (user == null) return null;

    final channel = _client
        .channel('resident-report-logs-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'report_logs',
          callback: (_) => onChange(),
        )
        .subscribe();

    return channel;
  }

  static Future<void> unsubscribeFromRealtime(RealtimeChannel? channel) async {
    if (channel == null) return;
    await _client.removeChannel(channel);
  }
}
