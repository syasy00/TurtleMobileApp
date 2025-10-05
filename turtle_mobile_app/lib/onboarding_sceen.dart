import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool showLogo = false;
  bool showText = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() => showLogo = true);
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      setState(() => showText = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00537E), // Deep Ocean Blue
              Color(0xFF3AA17E), // Soft Teal
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Fade-in logo + corners
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: showLogo ? 1 : 0,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Image.asset(
                      'assets/corner_top.png',
                      width: 180,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/corner_bottom.png',
                      width: 180,
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      'assets/smart_shell_logo.png',
                      width: MediaQuery.of(context).size.width * 0.75,
                    ),
                  ),
                ],
              ),
            ),

            // Fade-in welcome text + button
            AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: showText ? 1 : 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 300),
                    const Text(
                      'Welcome to Smart Shell',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Monitor and manage your turtle nest effortlessly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AuthScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 6,
                      ),
                      child: const Text('Get Started'),
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
}
