import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../shared/widgets/custom_drawer.dart';
import '../models/scan_file.dart';
import '../services/file_service.dart';
import '../services/upload_service.dart';
import '../services/file_actions_service.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({Key? key}) : super(key: key);

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final fileService = FileService();
  final actions = FileActionsService();
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
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: () {
                // TODO: connecter l’appareil
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                _loadFiles();
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('+ Upload STL', style: GoogleFonts.poppins(color: Colors.white)),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1, // chaque fichier occupe toute la largeur
            mainAxisSpacing: 16,
            childAspectRatio: 3.5, // ajustable si tu veux plus haut ou plus large
          ),
          itemBuilder: (context, index) {
            final file = files[index];
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.insert_drive_file, size: 60, color: Colors.deepPurpleAccent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      file.filename,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.white),
                        onPressed: () => actions.view(context, file),
                      ),
                      IconButton(
                        icon: const Icon(Icons.drive_file_rename_outline, color: Colors.white),
                        onPressed: () async {
                          await actions.rename(context, file);
                          _loadFiles();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.lightBlueAccent),
                        onPressed: () => actions.share(context, file),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          await actions.delete(context, file);
                          _loadFiles();
                        },
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
