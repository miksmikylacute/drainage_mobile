import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/app_service.dart';
import 'app_header.dart';
import '../widgets/app_alert_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notificationsFuture;
  RealtimeChannel? _notificationsChannel;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = AppService.fetchNotifications();
    _notificationsChannel = AppService.subscribeToNotificationChanges(() {
      if (!mounted) return;
      _refreshNotifications();
    });
  }

  @override
  void dispose() {
    AppService.unsubscribeFromRealtime(_notificationsChannel);
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _notificationsFuture = AppService.fetchNotifications();
    });
    await _notificationsFuture;
  }

  Future<void> _markAllAsRead() async {
    try {
      await AppService.markAllNotificationsAsRead();
      await _refreshNotifications();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to mark all as read: $error')),
      );
    }
  }

  Future<void> _openNotification(AppNotification item) async {
    if (!item.isRead) {
      try {
        await AppService.markNotificationAsRead(item.id);
        await _refreshNotifications();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to mark as read: $error')),
        );
      }
    }

    if (!mounted) return;
    await showAppAlertDialog(
      context: context,
      title: item.title,
      message: item.message.isEmpty ? 'No message provided.' : item.message,
      icon: Icons.notifications_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Notifications'),
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
                          color: Color(0xFF2196F3),
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

                    final hasUnread = notifications.any(
                      (notification) => !notification.isRead,
                    );

                    return RefreshIndicator(
                      onRefresh: _refreshNotifications,
                      color: const Color(0xFF2196F3),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: hasUnread ? _markAllAsRead : null,
                                icon: const Icon(
                                  Icons.done_all_rounded,
                                  size: 18,
                                ),
                                label: const Text('Read all'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0066FF),
                                  disabledForegroundColor: Colors.black26,
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...notifications.map(
                            (notification) =>
                                _buildNotificationCard(notification),
                          ),
                        ],
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
      color: const Color(0xFF2196F3),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openNotification(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFEAF4FF),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMM d, yyyy  •  h:mm a',
                    ).format(item.createdAt.toLocal()),
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
