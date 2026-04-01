import 'package:flutter/material.dart';
import 'page2.dart';
import 'page3.dart';

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60), 
            
            // Header: Logo and text
            // On utilise un Padding à DROITE pour pousser le contenu vers la GAUCHE
            Padding(
              padding: const EdgeInsets.only(right: 20), // Un petit décalage de 20 vers la gauche
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Reste centré par défaut
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
            
            // Image agrandie
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Image.asset(
                    'lib/images/page1.png',
                    height: 260, 
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 260,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Image not found',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Bloc de texte
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Text(
                    'Track your expenses',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2230),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'See where your money goes\nevery single day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8B92A5),
                      height: 1.5,
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
                _buildDot(isActive: true),
                _buildDot(
                  isActive: false, 
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Page2())),
                ),
                _buildDot(
                  isActive: false,
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Page3())),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Button "NEXT"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF1644FF),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1644FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Page2()),
                      );
                    },
                    child: const Center(
                      child: Text(
                        "LET'S GO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
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
        height: 5, 
        width: isActive ? 28 : 10,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1644FF) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}