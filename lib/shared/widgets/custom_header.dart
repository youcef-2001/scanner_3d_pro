import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hexagon_logo.dart';
import '../../features/auth/screens/login_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? user?.email ?? 'Utilisateur';

    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const HexagonLogo(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$userName',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(color: Colors.grey),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.greenAccent),
            title: const Text('Live View', style: TextStyle(color: Colors.greenAccent)),
            onTap: () {
              // TODO: Navigation LiveView
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder, color: Colors.blueAccent),
            title: const Text('3D Files', style: TextStyle(color: Colors.blueAccent)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
