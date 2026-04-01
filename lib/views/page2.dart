import 'package:flutter/material.dart';
import 'page3.dart';
import 'page1.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key});

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
                      color: const Color(0xFF1E283D),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // Image centrée et AGRANDIE
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Image.asset(
                    'lib/images/page2.png',
                    height: 210, // Augmenté de 180 à 210
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image, size: 210, color: Colors.grey[210]);
                    },
                  ),
                ),
              ),
            ),
            
            // Bloc de texte (Titre + Sous-titre)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Text(
                    'Control your monthly budget',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800, // Un peu plus gras
                      color: Color(0xFF1C2230),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Manage your expenses and stay stress‑free",
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
            
            // Transitions (Indicateurs de page)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(
                  isActive: false, 
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Page1())),
                ),
                _buildDot(isActive: true), 
                _buildDot(
                  isActive: false,
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Page3())),
                ),
              ],
            ),
            
            const SizedBox(height: 40), // Réduit légèrement pour équilibrer
            
            // Bouton LET'S GO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                height: 58, // Ajusté à 58 pour matcher Page 1
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
                        MaterialPageRoute(builder: (_) => const Page3()),
                      );
                    },
                    child: const Center(
                      child: Text(
                        "NEXT",
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
        width: isActive ? 28 : 12,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1644FF) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}