import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/drainage_report.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String get residentName {
    final metadata = currentUser?.userMetadata ?? {};
    return '${metadata['name'] ?? currentUser?.email ?? 'Resident'}';
  }

  static String get residentContact {
    final metadata = currentUser?.userMetadata ?? {};
    return '${metadata['contact_no'] ?? metadata['contact'] ?? ''}';
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String name,
    required String contactNo,
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'contact_no': contactNo},
    );

    try {
      await client.from('residents').insert({
        'name': name,
        'contact': contactNo,
        'email': email,
        'status': 'Active',
      });
    } catch (_) {
      // Auth signup is the source of truth; resident insert may be blocked by RLS.
    }

    return response;
  }

  static Future<void> signOut() {
    return client.auth.signOut();
  }

  /// Updates the resident's display name, phone, and optionally email.
  static Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
  }) async {
    final currentEmail = currentUser?.email ?? '';

    final response = await client.auth.updateUser(UserAttributes(
      email: (email.isNotEmpty && email != currentEmail) ? email : null,
      data: {'name': name, 'contact_no': phone},
    ));

    if (response.user == null) {
      throw Exception('Failed to update profile. Please try again.');
    }

    // Keep the residents table in sync (best-effort)
    try {
      final uid = currentUser?.id;
      if (uid != null) {
        await client.from('residents').update({
          'name': name,
          'contact': phone,
        }).eq('id', uid);
      }
    } catch (_) {}
  }

  /// Re-authenticates with [currentPassword] then updates to [newPassword].
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = currentUser?.email;
    if (email == null) throw Exception('No authenticated user.');

    // Re-authenticate to verify current password
    final signInRes =
        await client.auth.signInWithPassword(email: email, password: currentPassword);
    if (signInRes.user == null) {
      throw Exception('Current password is incorrect.');
    }

    // Update to new password
    final updateRes =
        await client.auth.updateUser(UserAttributes(password: newPassword));
    if (updateRes.user == null) {
      throw Exception('Failed to change password. Please try again.');
    }
  }

  static Future<String> uploadReportPhoto(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final filePath =
        '${DateTime.now().millisecondsSinceEpoch}-${currentUser?.id ?? 'anonymous'}.$safeExtension';

    await client.storage
        .from(SupabaseConfig.reportPhotosBucket)
        .upload(
          filePath,
          file,
          fileOptions: FileOptions(
            contentType: 'image/$safeExtension',
            upsert: false,
          ),
        );

    return client.storage
        .from(SupabaseConfig.reportPhotosBucket)
        .getPublicUrl(filePath);
  }

  static Future<DrainageReport> submitReport({
    required File photo,
    required String location,
    required String description,
  }) async {
    final imageUrl = await uploadReportPhoto(photo);
    final now = DateTime.now().toUtc().toIso8601String();

    final data = await client
        .from('reports')
        .insert({
          'issue': 'Drainage Issue',
          'location': location,
          'status': 'In Progress',
          'date_submitted': now,
          'submitted_by': residentName,
          'contact_no': residentContact.isEmpty ? null : residentContact,
          'description': description,
          'remarks': '',
          'map_coords': null,
          'lat_lng_label': location,
          'image_url': imageUrl,
        })
        .select()
        .single();

    return DrainageReport.fromMap(Map<String, dynamic>.from(data));
  }

  static Future<List<DrainageReport>> fetchMyReports() async {
    final data = await client
        .from('reports')
        .select('*')
        .order('created_at', ascending: false);
    final reports = (data as List)
        .map((item) => DrainageReport.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    final name = residentName.trim().toLowerCase();
    final contact = residentContact.trim();
    return reports.where((report) {
      final sameName = report.submittedBy.trim().toLowerCase() == name;
      final sameContact =
          contact.isNotEmpty && report.contactNo.trim() == contact;
      return sameName || sameContact;
    }).toList();
  }
}
