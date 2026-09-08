import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_service.dart';
import '../widgets/app_alert_dialog.dart';
import 'app_header.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _passwordFocusNode.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordFocusNode.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final newPassword = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      await AppService.updatePassword(newPassword);

      if (!mounted) return;

      await showAppAlertDialog(
        context: context,
        title: 'Password Changed',
        message:
            'Your password has been successfully updated. You can now sign in with your new password.',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF10B981),
      );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString().toLowerCase();
      String message = 'We could not update your password. Please try again.';

      if (rawError.contains('different')) {
        message = 'Your new password should be different from your old password.';
      } else {
        message = AppService.friendlyAuthError(e, fallback: message);
      }

      await showAppAlertDialog(
        context: context,
        title: 'Update Failed',
        message: message,
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFEF4444),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCheckItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: isMet ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isMet ? const Color(0xFF10B981) : const Color(0xFF64748B),
              fontWeight: isMet ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
    final hasMinLength = password.length >= 8;

    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(title: 'Reset Password'),

            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F6FB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set New Password',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your new password below to update your account.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // New Password Field
                        Text(
                          'New Password',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (!hasMinLength || !hasUpper || !hasLower || !hasDigit || !hasSymbol) {
                              return 'Password does not meet all criteria';
                            }
                            return null;
                          },
                        ),

                        // Password checklist
                        if (_passwordFocusNode.hasFocus || password.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCheckItem('At least 8 characters', hasMinLength),
                                _buildCheckItem('At least 1 uppercase letter (A-Z)', hasUpper),
                                _buildCheckItem('At least 1 lowercase letter (a-z)', hasLower),
                                _buildCheckItem('At least 1 number (0-9)', hasDigit),
                                _buildCheckItem('At least 1 special character (!@#\$%^&*)', hasSymbol),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        Text(
                          'Confirm New Password',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Confirm new password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleUpdatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Update Password',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Back to login
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF64748B)),
                            label: Text(
                              'Back to Login',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
}
