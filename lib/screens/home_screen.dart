import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drainage_report.dart';
import '../services/app_service.dart';
import 'account_screen.dart';
import 'login_screen.dart';
import 'my_reports_screen.dart';
import 'notifications_screen.dart';
import 'report_issue_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final residentName = AppService.residentName;

    return Scaffold(
      backgroundColor: const Color(0xFF38B6FF), // Blue top background
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Blue Header Profile Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Row(
                children: [
                  // Profile Avatar (tap to open Account page)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Greeting & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $residentName!',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Welcome to Drainage Reporting System',
                          style: GoogleFonts.poppins(
                            color: Colors.black.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions Section
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Actions Grid (2x2)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.15,
                        children: [
                          _buildActionCard(
                            icon: Icons.find_in_page_rounded,
                            iconColor: const Color(0xFF0066FF),
                            title: 'Report Issue',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReportIssueScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionCard(
                            icon: Icons.assignment_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'My Reports',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyReportsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionCard(
                            icon: Icons.notifications_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Notification',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionCard(
                            icon: Icons.logout_rounded,
                            iconColor: const Color(0xFFEF4444),
                            title: 'Logout',
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Text(
                                      'Logout',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    content: Text(
                                      'Do you want to logout?',
                                      style: GoogleFonts.poppins(
                                        color: Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                    actionsPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(
                                            context,
                                          ); // Close dialog
                                          await AppService.signOut();
                                          if (!context.mounted) return;
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginScreen(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFEF4444,
                                          ),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Logout',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Recent Report Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Report',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyReportsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View all >',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0066FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Recent Report List
                      FutureBuilder<List<DrainageReport>>(
                        future: AppService.fetchMyReports(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF38B6FF),
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
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
                              child: Center(
                                child: Text(
                                  'No recent reports found.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          final recentReports = snapshot.data!.take(3).toList();

                          return Column(
                            children: recentReports.map((report) {
                              Color badgeBgColor;
                              Color badgeTextColor;

                              switch (report.status) {
                                case 'Resolved':
                                  badgeBgColor = const Color(0xFFE2FBE9);
                                  badgeTextColor = const Color(0xFF10B981);
                                  break;
                                case 'Rejected':
                                  badgeBgColor = const Color(0xFFFCE8E6);
                                  badgeTextColor = const Color(0xFFEF4444);
                                  break;
                                case 'In Progress':
                                default:
                                  badgeBgColor = const Color(0xFFFFEAD6);
                                  badgeTextColor = const Color(0xFFE67E22);
                                  break;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: report.imageUrl.isNotEmpty
                                          ? Image.network(
                                              report.imageUrl,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Image.asset(
                                                      'assets/clogged_drain.png',
                                                      width: 70,
                                                      height: 70,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                            )
                                          : Image.asset(
                                              'assets/clogged_drain.png',
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.issue,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            report.location,
                                            style: GoogleFonts.poppins(
                                              color: Colors.black54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            report.formattedDate,
                                            style: GoogleFonts.poppins(
                                              color: Colors.black38,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Badge for status
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              report.status,
                                              style: GoogleFonts.poppins(
                                                color: badgeTextColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.black54,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Community Tip Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFD6EFFF,
                          ), // Light blue banner background
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.campaign_rounded,
                              color: Color(0xFF0066FF),
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Help keep out community clean by reporting drainage problems.',
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
