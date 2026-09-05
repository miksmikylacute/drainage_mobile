import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final waitFuture = Future.delayed(const Duration(milliseconds: 600));
    final sessionFuture = () async {
      try {
        await AppService.initializeSession();
      } catch (_) {
        await AppService.signOut();
      }
    }();

    await Future.wait([waitFuture, sessionFuture]);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AppService.isSignedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Image.asset(
                'assets/drain_alert_logo.png',
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              Text(
                'DRAINALERT',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2196F3),
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
