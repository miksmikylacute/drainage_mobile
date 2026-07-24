import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/drainage_report.dart';
import '../services/app_service.dart';

Future<void> showReportDetailSheet({
  required BuildContext context,
  required DrainageReport report,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ReportDetailSheet(initialReport: report),
  );
}

class ReportDetailSheet extends StatefulWidget {
  final DrainageReport initialReport;

  const ReportDetailSheet({super.key, required this.initialReport});

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  late Future<DrainageReport> _reportFuture;
  late Future<List<ReportLog>> _logsFuture;
  RealtimeChannel? _reportsChannel;
  RealtimeChannel? _logsChannel;

  @override
  void initState() {
    super.initState();
    _reportFuture = Future.value(widget.initialReport);
    _logsFuture = AppService.fetchReportLogs(widget.initialReport.id);
    _reportsChannel = AppService.subscribeToMyReportChanges(_refresh);
    _logsChannel = AppService.subscribeToReportLogChanges(_refresh);
  }

  @override
  void dispose() {
    AppService.unsubscribeFromRealtime(_reportsChannel);
    AppService.unsubscribeFromRealtime(_logsChannel);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _reportFuture = AppService.fetchReportById(widget.initialReport.id);
      _logsFuture = AppService.fetchReportLogs(widget.initialReport.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF3F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<DrainageReport>(
            future: _reportFuture,
            builder: (context, reportSnapshot) {
              final report = reportSnapshot.data ?? widget.initialReport;

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.displayId,
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.issue,
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => _showImagePreview(report),
                      child: report.imageUrl.isEmpty
                          ? _buildDetailImageFallback()
                          : Image.network(
                              report.imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildDetailImageFallback(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailPanel(report),
                  const SizedBox(height: 18),
                  Text(
                    'Timeline',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<ReportLog>>(
                    future: _logsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildTimelineMessage(
                          'Unable to load timeline.\n${snapshot.error}',
                        );
                      }

                      final logs = snapshot.data ?? [];
                      if (logs.isEmpty) {
                        return _buildTimelineMessage(
                          'No timeline updates yet.',
                        );
                      }

                      return Column(
                        children: logs
                            .map((log) => _buildTimelineItem(log))
                            .toList(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailPanel(DrainageReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow('Title', report.title),
          _buildDetailRow('Status', report.status),
          _buildDetailRow('Location', report.location),
          _buildDetailRow('Date Submitted', report.formattedDate),
          _buildDetailRow(
            'Description',
            report.description.isEmpty
                ? 'No description provided.'
                : report.description,
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePreview(DrainageReport report) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.72,
                    child: report.imageUrl.isEmpty
                        ? _buildFullImageFallback()
                        : Image.network(
                            report.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFullImageFallback(),
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ReportLog log) {
    final statusText = log.oldStatus == null
        ? log.newStatus
        : '${log.oldStatus} to ${log.newStatus}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _statusColor(log.newStatus).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.timeline_rounded,
              size: 18,
              color: _statusColor(log.newStatus),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat(
                    'MMM d, yyyy  h:mm a',
                  ).format(log.createdAt.toLocal()),
                  style: GoogleFonts.poppins(
                    color: Colors.black45,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (log.remarks.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    log.remarks,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
      ),
    );
  }

  Widget _buildDetailImageFallback() {
    return Image.asset(
      'assets/clogged_drain.png',
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 180,
          width: double.infinity,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildFullImageFallback() {
    return Image.asset(
      'assets/clogged_drain.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[900],
          child: const Icon(
            Icons.broken_image_outlined,
            color: Colors.white70,
            size: 42,
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFEF4444);
      case 'In Progress':
        return const Color(0xFF2563EB);
      case 'Resolved':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }
}
