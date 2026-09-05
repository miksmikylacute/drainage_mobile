import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IdCameraOverlayScreen extends StatefulWidget {
  final String title;

  const IdCameraOverlayScreen({
    super.key,
    required this.title,
  });

  static Future<XFile?> captureId({
    required BuildContext context,
    required String title,
  }) async {
    return Navigator.push<XFile?>(
      context,
      MaterialPageRoute(
        builder: (_) => IdCameraOverlayScreen(title: title),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<IdCameraOverlayScreen> createState() => _IdCameraOverlayScreenState();
}

class _IdCameraOverlayScreenState extends State<IdCameraOverlayScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
          _isInitializing = false;
        });
        return;
      }

      // Default to back camera
      final backIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIndex != -1 ? backIndex : 0;

      await _setupController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to initialize camera: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    final prev = _controller;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;

    try {
      await prev?.dispose();
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera setup failed: $e';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final nextMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isInitializing = true;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    await _setupController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take picture: $e')),
        );
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview
            if (!_isInitializing && _controller != null && _controller!.value.isInitialized)
              Center(
                child: CameraPreview(_controller!),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF2196F3)),
              ),

            // Box Overlay & Darkened Surround
            LayoutBuilder(
              builder: (context, constraints) {
                final boxWidth = constraints.maxWidth * 0.88;
                // Standard ID-1 card aspect ratio is 85.6mm x 53.98mm = ~1.586
                final boxHeight = boxWidth / 1.586;

                return Stack(
                  children: [
                    // Semi-transparent cutout overlay
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.65),
                        BlendMode.srcOut,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              backgroundBlendMode: BlendMode.dstOut,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: boxWidth,
                              height: boxHeight,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rectangular border and corner guides
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: boxWidth,
                        height: boxHeight,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF2196F3),
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // 4 White Corner Accents
                            _buildCornerAccent(top: true, left: true),
                            _buildCornerAccent(top: true, left: false),
                            _buildCornerAccent(top: false, left: true),
                            _buildCornerAccent(top: false, left: false),
                          ],
                        ),
                      ),
                    ),

                    // Top Bar
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _flashMode == FlashMode.torch
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: _flashMode == FlashMode.torch
                                  ? const Color(0xFFFFD54F)
                                  : Colors.white,
                              size: 26,
                            ),
                            onPressed: _toggleFlash,
                          ),
                        ],
                      ),
                    ),

                    // Hint Prompt above box
                    Positioned(
                      bottom: (constraints.maxHeight / 2) + (boxHeight / 2) + 16,
                      left: 20,
                      right: 20,
                      child: Text(
                        'Align your ID card inside the frame',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          shadows: [
                            const Shadow(
                              color: Colors.black87,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Controls Bar
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Switch Camera if available
                          _cameras.length > 1
                              ? IconButton(
                                  icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 28),
                                  onPressed: _switchCamera,
                                )
                              : const SizedBox(width: 48),

                          // Shutter Button
                          GestureDetector(
                            onTap: _isCapturing ? null : _takePicture,
                            child: Container(
                              width: 76,
                              height: 76,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isCapturing ? Colors.grey : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: _isCapturing
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF2196F3),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),

                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerAccent({required bool top, required bool left}) {
    return Positioned(
      top: top ? 4 : null,
      bottom: !top ? 4 : null,
      left: left ? 4 : null,
      right: !left ? 4 : null,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Colors.white, width: 3.5) : BorderSide.none,
            bottom: !top ? const BorderSide(color: Colors.white, width: 3.5) : BorderSide.none,
            left: left ? const BorderSide(color: Colors.white, width: 3.5) : BorderSide.none,
            right: !left ? const BorderSide(color: Colors.white, width: 3.5) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
