import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // --- Header Minimaliste ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'lib/images/logo2.png',
                        height: 28,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1D4ED8), size: 28),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'monex',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  // Bouton Déconnexion pour les tests
                  IconButton(
                    onPressed: () => authProvider.signOut(),
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),

              const Spacer(),

              // --- Message de Bienvenue Central ---
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Illustration ou Icône
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.waving_hand_rounded,
                        size: 60,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Texte de bienvenue
                    Text(
                      'Welcome \n$userName !',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Message temporaire
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Dashboard Overview Under Development',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}