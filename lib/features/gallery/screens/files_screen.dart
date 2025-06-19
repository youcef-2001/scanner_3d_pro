import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/custom_header.dart';
import '../models/scan_file.dart';
import '../services/file_service.dart';
import 'package:file_picker/file_picker.dart';
import '../services/upload_service.dart';
import 'dart:io';

class FilesScreen extends StatefulWidget {
  const FilesScreen({Key? key}) : super(key: key);

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final fileService = FileService();
  List<ScanFile> files = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final result = await fileService.getUserFiles();
    setState(() {
      files = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;
    final uploadService = UploadService();

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
          TextButton(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['stl'],
              );

              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                await uploadService.uploadSTL(file);
                _loadFiles(); // Recharge la liste
              }
            },
            child: Text('+ Upload STL', style: GoogleFonts.poppins(color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
          ? Center(
        child: Text(
          'Aucun fichier trouvé',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: GridView.builder(
          itemCount: files.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final file = files[index];
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
                    file.filename,
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
