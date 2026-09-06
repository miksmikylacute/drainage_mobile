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

class Hotline {
  final String id;
  final String name;
  final String phoneNumber;
  final String description;
  final String category;
  final bool isActive;

  const Hotline({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.description,
    required this.category,
    required this.isActive,
  });

  factory Hotline.fromSupabase(Map<String, dynamic> data) {
    return Hotline(
      id: '${data['id']}',
      name: '${data['name'] ?? 'Hotline'}',
      phoneNumber: '${data['phone_number'] ?? ''}',
      description: '${data['description'] ?? ''}',
      category: '${data['category'] ?? ''}',
      isActive: data['is_active'] != false,
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

    if (message.contains('disabled') ||
        message.contains('banned') ||
        message.contains('user_banned') ||
        message.contains('user is banned') ||
        message.contains('user is disabled') ||
        message.contains('account is disabled') ||
        message.contains('account disabled') ||
        message.contains('user unavailable') ||
        message.contains('storageexception') ||
        message.contains('row-level security') ||
        message.contains('violates row-level security')) {
      return 'User unavailable. Account disabled by admin.';
    }

    if (message.contains('under review') || message.contains('id is verified')) {
      return 'Your account registration is under review by Barangay Soledad admins. You will receive full access once your ID is verified.';
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

    if (message.contains('bucket not found') ||
        message.contains('resident-ids') ||
        (message.contains('storage') && message.contains('bucket'))) {
      return 'Storage setup required: The resident-ids bucket is missing in Supabase. Please execute migrations 0011 and 0012 in your Supabase SQL editor.';
    }

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('clientexception') ||
        message.contains('network is unreachable') ||
        message.contains('network error') ||
        message.contains('connection refused') ||
        message.contains('connection timed out') ||
        message.contains('failed to fetch') ||
        message.contains('no address associated with hostname') ||
        message.contains('handshakeexception') ||
        message.contains('httpexception')) {
      return 'No Internet Connection';
    }

    final rawErr = error.toString().replaceFirst('Exception: ', '').trim();
    if (rawErr.isNotEmpty &&
        !rawErr.toLowerCase().contains('storageexception') &&
        !rawErr.toLowerCase().contains('row-level security') &&
        !rawErr.toLowerCase().contains('postgrestexception')) {
      return '$fallback\n\nDetails: $rawErr';
    }

    return fallback;
  }

  static String friendlyErrorMessage(Object error, {String fallback = 'An unexpected error occurred.'}) {
    final message = error.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('clientexception') ||
        message.contains('network is unreachable') ||
        message.contains('network error') ||
        message.contains('connection refused') ||
        message.contains('connection timed out') ||
        message.contains('failed to fetch') ||
        message.contains('no address associated with hostname') ||
        message.contains('handshakeexception') ||
        message.contains('httpexception')) {
      return 'No Internet Connection';
    }
    return friendlyAuthError(error, fallback: fallback);
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

    if (status != 'Active' && status != 'Pending') {
      await _client.auth.signOut();
      _currentUser = null;
      throw Exception('User Unavailable. Account disabled by the Admin');
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

  static bool get isPending {
    final status = currentUser?.userMetadata['status'];
    return status == 'Pending';
  }

  static bool get isVerified {
    final status = currentUser?.userMetadata['status'];
    return status == 'Active';
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
    required XFile idCardFrontMedia,
    required XFile idCardBackMedia,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'role': 'resident',
        'fullname': name.trim(),
        'phone': contactNo.trim(),
        'status': 'Pending',
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Unable to create account.');
    }

    if (_client.auth.currentSession == null) {
      try {
        await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
      } catch (_) {}
    }

    String frontUrl = '';
    String backUrl = '';
    try {
      frontUrl = await _uploadResidentIdMedia(idCardFrontMedia, 'front');
      backUrl = await _uploadResidentIdMedia(idCardBackMedia, 'back');
    } catch (storageError) {
      throw Exception(
        'ID Photo Upload Failed: Storage bucket "resident-ids" does not exist or permission denied. Please run migrations 0011 and 0012 in your Supabase SQL Editor. ($storageError)',
      );
    }

    try {
      await _client.from('users').upsert({
        'id': user.id,
        'email': email.trim(),
        'fullname': name.trim(),
        'phone': contactNo.trim(),
        'id_card_url': frontUrl,
        'id_card_front_url': frontUrl,
        'id_card_back_url': backUrl,
        'role': 'resident',
        'status': 'Pending',
      });
    } catch (dbError) {
      throw Exception(
        'Database update failed: Please run migrations 0011 and 0012 in your Supabase SQL Editor. ($dbError)',
      );
    }

    await _client.auth.signOut();
    _currentUser = null;
  }

  static Future<String> _uploadResidentIdMedia(XFile media, String side) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user.');

    final rawExtension = media.name.split('.').last.toLowerCase();
    final extension = ['jpg', 'jpeg', 'png', 'webp'].contains(rawExtension)
        ? rawExtension
        : 'jpg';
    final path =
        '${user.id}/${side}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final bytes = await media.readAsBytes();

    final mimeType = extension == 'png'
        ? 'image/png'
        : extension == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

    await _client.storage.from('resident-ids').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: mimeType),
        );

    return _client.storage.from('resident-ids').getPublicUrl(path);
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
      case '3gp':
        return 'video/3gpp';
      case 'avi':
        return 'video/avi';
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
      '3gp',
      'avi',
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
      case 'video/3gpp':
      case 'video/3gpp2':
        return '3gp';
      case 'video/avi':
      case 'video/x-msvideo':
        return 'avi';
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

    // Proactively verify the user account is still Active and not Disabled
    final profile = await _client
        .from('users')
        .select('status, role')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null || profile['status'] == 'Disabled') {
      await signOut();
      throw Exception('User unavailable. Account disabled by admin.');
    }

    if (profile['status'] == 'Pending') {
      throw Exception('Your account is pending verification by the admin.');
    }

    String mediaUrl;
    try {
      mediaUrl = await _uploadReportMedia(media);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('violates row-level security') ||
          msg.contains('row-level security') ||
          msg.contains('unauthorized') ||
          msg.contains('storageexception') ||
          msg.contains('statuscode: 403') ||
          msg.contains('statuscode: 401')) {
        await signOut();
        throw Exception('User unavailable. Account disabled by admin.');
      }
      rethrow;
    }

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

  static Future<void> clearAllNotifications() async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    try {
      await _client.rpc('clear_resident_notifications');
    } catch (_) {
      // Fallback direct delete under RLS policy
      await _client
          .from('notifications')
          .delete()
          .eq('user_id', user.id);
    }
  }

  static Future<void> deleteNotification(String id) async {
    final user = _currentUser;
    if (user == null) throw Exception('No authenticated user.');

    try {
      await _client.rpc(
        'delete_resident_notification',
        params: {'p_notification_id': id},
      );
    } catch (_) {
      // Fallback direct delete under RLS policy
      await _client
          .from('notifications')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    }
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

  static Future<List<Hotline>> fetchHotlines() async {
    final user = _currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('hotlines')
        .select('id,name,phone_number,description,category,is_active,sort_order')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true);

    return (rows as List<dynamic>)
        .map((row) => Hotline.fromSupabase(row as Map<String, dynamic>))
        .toList();
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

  static RealtimeChannel? subscribeToHotlineChanges(void Function() onChange) {
    final user = _currentUser;
    if (user == null) return null;

    final channel = _client
        .channel('resident-hotlines-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'hotlines',
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
