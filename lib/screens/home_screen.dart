import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_service.dart';
import 'account_screen.dart';
import 'login_screen.dart';
import 'my_reports_screen.dart';
import 'notifications_screen.dart';
import 'report_detail_sheet.dart';
import 'report_issue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<ResidentDashboardSummary> _dashboardFuture;
  late Future<int> _unreadNotificationCountFuture;
  RealtimeChannel? _reportsChannel;
  RealtimeChannel? _notificationsChannel;

  @override
  void initState() {
    super.initState();
    _setDashboardFuture(AppService.fetchResidentDashboardSummary());
    _reportsChannel = AppService.subscribeToMyReportChanges(_reloadDashboard);
    _notificationsChannel = AppService.subscribeToNotificationChanges(
      _reloadDashboard,
    );
  }

  @override
  void dispose() {
    AppService.unsubscribeFromRealtime(_reportsChannel);
    AppService.unsubscribeFromRealtime(_notificationsChannel);
    super.dispose();
  }

  void _reloadDashboard() {
    if (!mounted) return;
    setState(() {
      _setDashboardFuture(AppService.fetchResidentDashboardSummary());
    });
  }

  Future<void> _refreshDashboard() async {
    await AppService.refreshCurrentUser();
    final nextDashboard = AppService.fetchResidentDashboardSummary();
    if (!mounted) return;
    setState(() {
      _setDashboardFuture(nextDashboard);
    });
    await nextDashboard;
  }

  void _setDashboardFuture(Future<ResidentDashboardSummary> dashboardFuture) {
    _dashboardFuture = dashboardFuture;
    _unreadNotificationCountFuture = dashboardFuture.then(
      (summary) => summary.unreadNotificationCount,
    );
  }



  @override
  Widget build(BuildContext context) {
    final residentName = AppService.residentName;
    final avatarUrl = AppService.avatarUrl;

    return Scaffold(
      backgroundColor: const Color(0xFF2196F3), // Blue top background
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
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountScreen(),
                        ),
                      );
                      if (!context.mounted) return;
                      setState(() {});
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 36,
                              color: Colors.black,
                            )
                          : null,
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
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Welcome to Drainage Reporting System',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Top Right Icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationsScreen(),
                                ),
                              );
                              if (!context.mounted) return;
                              _reloadDashboard();
                            },
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: FutureBuilder<int>(
                              future: _unreadNotificationCountFuture,
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                if (count <= 0) return const SizedBox.shrink();

                                return Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFF2196F3),
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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
                child: RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  color: const Color(0xFF2196F3),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
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

                        // Quick Actions Row (2 items)
                        Row(
                          children: [
                            _buildExpandedActionCard(
                              imagePath: 'assets/icon_report_issue.png',
                              title: 'Report Issue',
                              subtitle: 'Report drainage problems\nin your area.',
                              color: const Color(0xFF1E88E5), // Blue
                              bgColor: const Color(0xFFE3F2FD), // Light blue
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
                            const SizedBox(width: 16),
                            _buildExpandedActionCard(
                              imagePath: 'assets/icon_my_reports.png',
                              title: 'My Reports',
                              subtitle: 'View and track the status\nof your reports.',
                              color: const Color(0xFF22C55E), // Green
                              bgColor: const Color(0xFFDCFCE7), // Light green
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyReportsScreen(),
                                  ),
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
                                    builder: (context) =>
                                        const MyReportsScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'View all >',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Recent Report List
                        FutureBuilder<ResidentDashboardSummary>(
                          future: _dashboardFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                              );
                            }
                            final recentReports =
                                snapshot.data?.recentReports ?? [];
                            if (snapshot.hasError || recentReports.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
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

                            return Column(
                              children: recentReports.map((report) {
                                Color badgeBgColor;
                                Color badgeTextColor;

                                switch (report.status) {
                                  case 'Pending':
                                    badgeBgColor = const Color(0xFFFFF9E6);
                                    badgeTextColor = const Color(0xFFFFC107);
                                    break;
                                  case 'Resolved':
                                    badgeBgColor = const Color(0xFFE6FCF2);
                                    badgeTextColor = const Color(0xFF22C55E);
                                    break;
                                  case 'Rejected':
                                    badgeBgColor = const Color(0xFFFEF2F2);
                                    badgeTextColor = const Color(0xFFEF4444);
                                    break;
                                  case 'In Progress':
                                  default:
                                    badgeBgColor = const Color(0xFFEBF5FF);
                                    badgeTextColor = const Color(0xFF3B82F6);
                                    break;
                                }

                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => showReportDetailSheet(
                                    context: context,
                                    report: report,
                                  ),
                                  child: Container(
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: report.imageUrl.isNotEmpty
                                              ? Image.network(
                                                  report.imageUrl,
                                                  width: 70,
                                                  height: 70,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
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
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                report.location,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                  'Help keep our community clean by reporting drainage problems.',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedActionCard({
    required String imagePath,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    imagePath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    color: bgColor,
                    colorBlendMode: BlendMode.multiply,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
