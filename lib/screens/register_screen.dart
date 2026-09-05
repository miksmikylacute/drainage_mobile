import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_service.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/id_camera_overlay_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  XFile? _selectedIdCardFrontMedia;
  Uint8List? _selectedIdCardFrontBytes;
  XFile? _selectedIdCardBackMedia;
  Uint8List? _selectedIdCardBackBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickIdCardImage(ImageSource source, {required bool isFront}) async {
    try {
      XFile? pickedFile;
      if (source == ImageSource.camera) {
        try {
          pickedFile = await IdCameraOverlayScreen.captureId(
            context: context,
            title: isFront ? 'Front of ID' : 'Back of ID',
          );
        } catch (_) {
          pickedFile = null;
        }

        // Fallback to ImagePicker only if custom camera fails or is unsupported
        if (pickedFile == null && !mounted) return;
        if (pickedFile == null) {
          // If canceled by user, don't force another dialog
          return;
        }
      } else {
        final picker = ImagePicker();
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
      }

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (isFront) {
            _selectedIdCardFrontMedia = pickedFile;
            _selectedIdCardFrontBytes = bytes;
          } else {
            _selectedIdCardBackMedia = pickedFile;
            _selectedIdCardBackBytes = bytes;
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to access camera or gallery for ID photo.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedIdCardFrontMedia == null || _selectedIdCardBackMedia == null) {
        await showAppAlertDialog(
          context: context,
          title: 'Valid ID Photos Required',
          message:
              'Please capture or upload clear front and back photos of your valid ID to complete registration.',
          icon: Icons.badge_rounded,
          color: const Color(0xFFEF4444),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await AppService.signUp(
          name: _nameController.text.trim(),
          contactNo: _contactController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          idCardFrontMedia: _selectedIdCardFrontMedia!,
          idCardBackMedia: _selectedIdCardBackMedia!,
        );

        if (!mounted) return;

        await showAppAlertDialog(
          context: context,
          title: 'Registration Submitted',
          message:
              'Your registration and valid ID photos have been submitted to Barangay Soledad admins for verification. You can log in to check your dashboard, and reporting will unlock once your account is verified.',
          icon: Icons.verified_user_rounded,
          color: const Color(0xFF22C55E),
        );

        if (!mounted) return;
        Navigator.pop(context);
      } catch (error) {
        if (!mounted) return;
        await showAppAlertDialog(
          context: context,
          title: 'Registration Failed',
          message: AppService.friendlyAuthError(
            error,
            fallback:
                'We could not create your account. Please check your details and try again.',
          ),
          icon: Icons.person_off_rounded,
          color: const Color(0xFFEF4444),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildIdPickerCard({
    required String title,
    required Uint8List? bytes,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required VoidCallback onClear,
  }) {
    final hasImage = bytes != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasImage ? const Color(0xFF2196F3) : const Color(0xFFD1D5DB),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasImage ? Icons.check_circle_rounded : Icons.credit_card_rounded,
                size: 14,
                color: hasImage ? const Color(0xFF22C55E) : const Color(0xFF2196F3),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasImage)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    bytes,
                    height: 64,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 13),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onCamera,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Color(0xFF2196F3),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Camera',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: onGallery,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 16,
                            color: Color(0xFF4B5563),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gallery',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.black38, size: 20),
      suffixIcon: suffixIcon,
      fillColor: const Color(0xFFF8FAFC),
      filled: true,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 12.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 11, height: 1.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Aesthetic Header (Compact & Aligned)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.black,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create an Account',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Fill in details & upload your valid ID',
                              style: GoogleFonts.poppins(
                                color: const Color(0xB3000000),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fields Container (Compact vertical gaps)
                  Column(
                    children: [
                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: _inputDecoration(
                          hintText: 'Full Name',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Contact Number
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: _inputDecoration(
                          hintText: 'Contact Number',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your contact number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: _inputDecoration(
                          hintText: 'Email Address',
                          icon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Password with parameter validations
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: _inputDecoration(
                          hintText: 'Password',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.black38,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Must be at least 8 characters';
                          }
                          if (!RegExp(r'[a-z]').hasMatch(value)) {
                            return 'Must include at least 1 lowercase letter';
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(value)) {
                            return 'Must include at least 1 uppercase letter';
                          }
                          if (!RegExp(r'[0-9]').hasMatch(value)) {
                            return 'Must include at least 1 number';
                          }
                          if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
                            return 'Must include at least 1 symbol';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: _inputDecoration(
                          hintText: 'Confirm Password',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.black38,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Side-by-Side Front & Back ID Card Row (Fits 1 Page)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedIdCardFrontMedia != null &&
                                    _selectedIdCardBackMedia != null
                                ? const Color(0xFF2196F3)
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  color: Color(0xFF2196F3),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Valid ID Photos (Required)',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Capture front and back within the camera guide box.',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildIdPickerCard(
                                    title: 'Front of ID',
                                    bytes: _selectedIdCardFrontBytes,
                                    onCamera: () => _pickIdCardImage(
                                      ImageSource.camera,
                                      isFront: true,
                                    ),
                                    onGallery: () => _pickIdCardImage(
                                      ImageSource.gallery,
                                      isFront: true,
                                    ),
                                    onClear: () {
                                      setState(() {
                                        _selectedIdCardFrontMedia = null;
                                        _selectedIdCardFrontBytes = null;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildIdPickerCard(
                                    title: 'Back of ID',
                                    bytes: _selectedIdCardBackBytes,
                                    onCamera: () => _pickIdCardImage(
                                      ImageSource.camera,
                                      isFront: false,
                                    ),
                                    onGallery: () => _pickIdCardImage(
                                      ImageSource.gallery,
                                      isFront: false,
                                    ),
                                    onClear: () {
                                      setState(() {
                                        _selectedIdCardBackMedia = null;
                                        _selectedIdCardBackBytes = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : Text(
                              'REGISTER',
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Already have an account? Login here
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 12.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Login here',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2196F3),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
