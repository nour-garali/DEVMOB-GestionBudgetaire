import 'package:flutter/material.dart';
import 'auth/LoginPage.dart';
import 'page1.dart';
import 'page2.dart';

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60), 
            
            // Header: Logo and text
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('lib/images/logo2.png', height: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'monex',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E283D),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Image centrée - Rendu un peu plus petit (200)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Center(
                  child: Image.asset(
                    'lib/images/page3.png',
                    height: 230, // Réduit de 250 à 180
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 230,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text('Image not found', style: TextStyle(color: Colors.blue)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Texte placé directement au-dessus des points
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Text(
                    'Easy to Track and Analyze',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C2230),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tracking your expense help make sure\nyou don't overspend",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8B92A5),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(
                  isActive: false, 
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Page1())),
                ),
                _buildDot(
                  isActive: false, 
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Page2())),
                ),
                _buildDot(isActive: true), 
              ],
            ),

            const SizedBox(height: 48),

            // Bouton final
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1644FF),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1644FF).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Center(
                      child: Text(
                        "GET STARTED",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 4, 
        width: isActive ? 28 : 12,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1644FF) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}