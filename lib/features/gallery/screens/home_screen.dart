import 'package:flutter/material.dart';
import 'package:scanner_3d_pro/shared/widgets/custom_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveDisabled extends StatelessWidget {
  const LiveDisabled({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? user?.email ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      drawer: const CustomDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32), // Espac en haut

            // Top - profil utilisateur
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://cdn.builder.io/api/v1/image/assets/TEMP/b3a41f38f7854aaa0820549c34ec57392c4d4d71?placeholderIfAbsent=true&apiKey=91c478f48c2b4da09ef24f4c421f135c',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                'Welcome back',
                                style: TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFEF4444),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.circle, size: 8, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Connect Device',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                     
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32), // Espace avant le bloc central

            // Bloc principal
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2A2A2A),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 1.0,
                    height: MediaQuery.of(context).size.height * 0.55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://cdn.builder.io/api/v1/image/assets/TEMP/f2e7761cc87b07c06510fc935fca3ba9fbf39f39?placeholderIfAbsent=true&apiKey=91c478f48c2b4da09ef24f4c421f135c',
                        ),
                        fit: BoxFit.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Camera Found',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect your device to start scanning',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Boutons en bas
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.block, color: Color(0xFF666666), size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isSmallScreen ? 'Disable' : 'Disable Lasers',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Start Scan',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
}
