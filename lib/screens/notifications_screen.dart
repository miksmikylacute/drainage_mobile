import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/app_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = AppService.fetchNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _notificationsFuture = AppService.fetchNotifications();
    });
    await _notificationsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF38B6FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: FutureBuilder<List<AppNotification>>(
                  future: _notificationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF38B6FF),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildMessage(
                        'Unable to load notifications.\n${snapshot.error}',
                        showRefresh: true,
                      );
                    }

                    final notifications = snapshot.data ?? [];
                    if (notifications.isEmpty) {
                      return _buildMessage(
                        'No notifications yet.',
                        showRefresh: true,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshNotifications,
                      color: const Color(0xFF38B6FF),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          24.0,
                          20.0,
                          24.0,
                        ),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(notifications[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String message, {bool showRefresh = false}) {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: const Color(0xFF38B6FF),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 14),
          ),
          if (showRefresh) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _refreshNotifications,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIcon(item),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy  •  h:mm a').format(item.createdAt),
                  style: GoogleFonts.poppins(
                    color: Colors.black38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(AppNotification item) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : const Color(0xFF0066FF),
        shape: BoxShape.circle,
        border: item.isRead
            ? Border.all(color: const Color(0xFF0066FF), width: 2)
            : null,
      ),
      child: Icon(
        item.isRead
            ? Icons.notifications_none_rounded
            : Icons.notifications_rounded,
        color: item.isRead ? const Color(0xFF0066FF) : Colors.white,
        size: 24,
      ),
    );
  }
}
