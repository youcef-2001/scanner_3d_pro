import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_header.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Fichiers 3D',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 18 : 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: () {
                // TODO: Connecter l'appareil
              },
              icon: const Icon(Icons.usb, size: 16, color: Colors.white),
              label: Text(
                'Connect Device',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Recharger les fichiers
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: GridView.builder(
          itemCount: 6, // TODO: Charger dynamiquement les fichiers
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
                  const Icon(
                    Icons.insert_drive_file,
                    size: 60,
                    color: Colors.deepPurpleAccent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'scan_${index + 1}.stl',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Icon(Icons.visibility, color: Colors.white),
                      Icon(Icons.drive_file_rename_outline, color: Colors.white),
                      Icon(Icons.share_outlined, color: Colors.lightBlueAccent),
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
