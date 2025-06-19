import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './home_screen.dart';
import '../../../shared/widgets/hexagon_logo.dart';
 
class FilesScreen extends StatelessWidget {
  const FilesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {// tester un merge parfait
    final isMobile = MediaQuery.of(context).size.width < 640;

    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? user?.email ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const HexagonLogo(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('$userName',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  )),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.greenAccent),
              title: const Text('Live View',
                  style: TextStyle(color: Colors.greenAccent)),
              onTap: () {
                Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LiveDisabled()
            ),
          );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blueAccent),
              title: const Text('3D Files',
                  style: TextStyle(color: Colors.blueAccent)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Déconnexion',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Mes Fichiers 3D',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: isMobile ? 20 : 28),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Recharger les fichiers depuis Supabase
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: GridView.builder(
          itemCount: 6, // TODO: Remplacer par la vraie liste
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Icon(Icons.insert_drive_file,
                      size: 60, color: Colors.deepPurpleAccent),
                  const SizedBox(height: 10),
                  Text(
                    'scan_${index + 1}.stl',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Icon(Icons.visibility, color: Colors.white),
                      Icon(Icons.drive_file_rename_outline,
                          color: Colors.white),
                      Icon(Icons.share_outlined,
                          color: Colors.lightBlueAccent),
                      Icon(Icons.delete_outline, color: Colors.redAccent),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
