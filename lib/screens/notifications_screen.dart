import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationItem {
  final String title;
  final String dateTime;
  final IconData icon;
  final Color iconColor;
  final bool
  isCircularIcon; // design detail: circular filled background or plain icon

  NotificationItem({
    required this.title,
    required this.dateTime,
    required this.icon,
    required this.iconColor,
    this.isCircularIcon = false,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<NotificationItem> notifications = [
      NotificationItem(
        title: 'Your report is now In Progress',
        dateTime: 'May 20, 2026  •  10:30 AM',
        icon: Icons.pending_actions_rounded,
        iconColor: const Color(0xFFFFB057),
      ),
      NotificationItem(
        title: 'Your report has been resolved. Thank you!',
        dateTime: 'May 20, 2026  •  10:30 AM',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF10B981),
        isCircularIcon: true,
      ),
      NotificationItem(
        title: 'New update on your reported issue.',
        dateTime: 'May 20, 2026  •  10:30 AM',
        icon: Icons.info_rounded,
        iconColor: const Color(0xFF0066FF),
        isCircularIcon: true,
      ),
      NotificationItem(
        title: 'Please check the status of your report.',
        dateTime: 'May 20, 2026  •  10:30 AM',
        icon: Icons.notifications_rounded,
        iconColor: const Color(0xFFF59E0B),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF38B6FF), // Blue top background
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  // Back Button (Black circle with white arrow)
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

            // White Content Body
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F7FA), // Soft light background
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          24.0,
                          20.0,
                          24.0,
                        ),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return _buildNotificationCard(item);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
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
          // Icon Box
          _buildIcon(item),
          const SizedBox(width: 16),

          // Details Text
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
                const SizedBox(height: 4),
                Text(
                  item.dateTime,
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

  Widget _buildIcon(NotificationItem item) {
    if (item.isCircularIcon) {
      // Circular filled background (for green/blue checklist/info icons)
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: item.iconColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          item.icon == Icons.check_circle_rounded
              ? Icons.check_rounded
              : Icons.priority_high_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    } else {
      // Regular icon (e.g., orange pending/dashboard or yellow bell)
      if (item.icon == Icons.pending_actions_rounded) {
        // Design matches the mockup: circle outline with check and dashed look
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: item.iconColor.withValues(alpha: 0.5),
              width: 3,
              style: BorderStyle.solid,
            ),
          ),
          child: Icon(Icons.check_rounded, color: item.iconColor, size: 24),
        );
      }
      return Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(item.icon, color: item.iconColor, size: 38),
      );
    }
  }
}
