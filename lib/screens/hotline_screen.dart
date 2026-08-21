import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/app_service.dart';
import 'app_header.dart';

class HotlineScreen extends StatefulWidget {
  const HotlineScreen({super.key});

  @override
  State<HotlineScreen> createState() => _HotlineScreenState();
}

class _HotlineScreenState extends State<HotlineScreen> {
  late Future<List<Hotline>> _hotlinesFuture;
  RealtimeChannel? _hotlinesChannel;

  @override
  void initState() {
    super.initState();
    _hotlinesFuture = AppService.fetchHotlines();
    _hotlinesChannel = AppService.subscribeToHotlineChanges(_reloadHotlines);
  }

  @override
  void dispose() {
    AppService.unsubscribeFromRealtime(_hotlinesChannel);
    super.dispose();
  }

  void _reloadHotlines() {
    if (!mounted) return;
    setState(() {
      _hotlinesFuture = AppService.fetchHotlines();
    });
  }

  Future<void> _refreshHotlines() async {
    setState(() {
      _hotlinesFuture = AppService.fetchHotlines();
    });
    await _hotlinesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(title: 'Hotlines'),
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: FutureBuilder<List<Hotline>>(
                  future: _hotlinesFuture,
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
                        'Unable to load hotlines.\n${snapshot.error}',
                        showRefresh: true,
                      );
                    }

                    final hotlines = snapshot.data ?? [];
                    if (hotlines.isEmpty) {
                      return _buildMessage(
                        'No hotlines available yet.',
                        showRefresh: true,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshHotlines,
                      color: const Color(0xFF2196F3),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: hotlines.length,
                        itemBuilder: (context, index) {
                          return _buildHotlineCard(hotlines[index]);
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
      onRefresh: _refreshHotlines,
      color: const Color(0xFF2196F3),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
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
                onPressed: _refreshHotlines,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHotlineCard(Hotline hotline) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              color: Color(0xFF2196F3),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hotline.category.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hotline.category,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1D4ED8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  hotline.name,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  hotline.phoneNumber,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hotline.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    hotline.description,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.35,
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
}
