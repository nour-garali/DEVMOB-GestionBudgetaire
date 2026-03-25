import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // --- CONTENU DU HAUT (Logo + Nom) ---
            Align(
              alignment: const Alignment(0, -0.4), 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('lib/images/logo2.png', width: 140),
                  const SizedBox(height: 24),
                  const Text(
                    "monex",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2230),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Smart money starts here",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTENU DU BAS (Loader) ---
            Positioned(
              bottom: 110, // Augmenté de 60 à 120 pour faire remonter le bloc
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1644FF)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading data...",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[400],
                        letterSpacing: 0.5,
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
}