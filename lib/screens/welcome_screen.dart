import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Logo
            Image.asset(
              'assets/drainage.png',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            // App Name
            Text(
              'REPORT DRAINAGE',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF38B6FF),
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            // Welcome text
            Text(
              'Welcome!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Text(
                'Report and monitor\ndrainage-related issues\nin your community.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Check if user is already logged in
                    final session =
                        Supabase.instance.client.auth.currentSession;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => session == null
                            ? const LoginScreen()
                            : const HomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B6FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'GET STARTED',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
