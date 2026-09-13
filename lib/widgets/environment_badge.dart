import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/supabase_config.dart';

class EnvironmentBadge extends StatelessWidget {
  final bool compact;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const EnvironmentBadge({
    super.key,
    this.compact = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isTestEnvironment) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFFEF3C7), // Amber 100
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? const Color(0xFFF59E0B), // Amber 500
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.science_rounded,
            size: compact ? 11 : 13,
            color: textColor ?? const Color(0xFFB45309), // Amber 700
          ),
          const SizedBox(width: 4),
          Text(
            compact ? 'TEST' : 'TEST ENV',
            style: GoogleFonts.poppins(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: textColor ?? const Color(0xFFB45309),
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
