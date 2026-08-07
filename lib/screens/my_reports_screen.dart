import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/drainage_report.dart';
import '../services/app_service.dart';
import 'app_header.dart';
import 'report_detail_sheet.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _selectedTab = 'All';
  late Future<List<DrainageReport>> _reportsFuture;
  RealtimeChannel? _reportsChannel;
  RealtimeChannel? _reportLogsChannel;

  @override
  void initState() {
    super.initState();
    _reportsFuture = AppService.fetchMyReports();
    _reportsChannel = AppService.subscribeToMyReportChanges(_reloadReports);
    _reportLogsChannel = AppService.subscribeToReportLogChanges(_reloadReports);
  }

  @override
  void dispose() {
    AppService.unsubscribeFromRealtime(_reportsChannel);
    AppService.unsubscribeFromRealtime(_reportLogsChannel);
    super.dispose();
  }

  void _reloadReports() {
    if (!mounted) return;
    setState(() {
      _reportsFuture = AppService.fetchMyReports();
    });
  }

  Future<void> _refreshReports() async {
    setState(() {
      _reportsFuture = AppService.fetchMyReports();
    });
    await _reportsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(title: 'My Reports'),
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        20.0,
                        16.0,
                        10.0,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            'All',
                            'Pending',
                            'In Progress',
                            'Resolved',
                            'Rejected',
                          ].map((tab) => _buildTabItem(tab)).toList(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.black12),
                    Expanded(
                      child: FutureBuilder<List<DrainageReport>>(
                        future: _reportsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2196F3),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return _buildMessage(
                              'Unable to load reports.\n${snapshot.error}',
                              showRefresh: true,
                            );
                          }

                          final reports = snapshot.data ?? [];
                          final filteredReports = _selectedTab == 'All'
                              ? reports
                              : reports
                                    .where(
                                      (report) => report.status == _selectedTab,
                                    )
                                    .toList();

                          if (filteredReports.isEmpty) {
                            return _buildMessage(
                              'No reports found for this filter.',
                              showRefresh: true,
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: _refreshReports,
                            color: const Color(0xFF2196F3),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20.0),
                              itemCount: filteredReports.length,
                              itemBuilder: (context, index) {
                                final report = filteredReports[index];
                                return _buildReportCard(report);
                              },
                            ),
                          );
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

  Widget _buildMessage(String message, {bool showRefresh = false}) {
    return RefreshIndicator(
      onRefresh: _refreshReports,
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
                onPressed: _refreshReports,
                icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabItem(String tabName) {
    final isSelected = _selectedTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabName;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tabName,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(DrainageReport report) {
    Color badgeBgColor;
    Color badgeTextColor;

    switch (report.status) {
      case 'Pending':
        badgeBgColor = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFFEF4444);
        break;
      case 'Resolved':
        badgeBgColor = const Color(0xFFE2FBE9);
        badgeTextColor = const Color(0xFF10B981);
        break;
      case 'Rejected':
        badgeBgColor = const Color(0xFFF3E8FF);
        badgeTextColor = const Color(0xFF8B5CF6);
        break;
      case 'In Progress':
      default:
        badgeBgColor = const Color(0xFFDBEAFE);
        badgeTextColor = const Color(0xFF2563EB);
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showReportDetails(report),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(12.0),
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
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: !report.hasMedia
                  ? _buildImageFallback()
                  : report.isVideo
                  ? _buildVideoThumbnail()
                  : Image.network(
                      report.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImageFallback(),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(20),
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
  }

  Future<void> _showReportDetails(DrainageReport report) async {
    await showReportDetailSheet(context: context, report: report);
  }
}

extension _ReportImageFallback on _MyReportsScreenState {
  Widget _buildImageFallback() {
    return Image.asset(
      'assets/clogged_drain.png',
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 70,
          height: 70,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildVideoThumbnail() {
    return Container(
      width: 70,
      height: 70,
      color: const Color(0xFFEAF2FF),
      child: const Icon(
        Icons.play_circle_fill_rounded,
        color: Color(0xFF0066FF),
        size: 34,
      ),
    );
  }
}
