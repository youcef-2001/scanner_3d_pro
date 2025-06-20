import 'dart:io';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadService {
  final _client = Supabase.instance.client;
  final String bucket = 'scans';

  Future<void> uploadSTL(File file) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final userId = user.id;
    final fileName = basename(file.path);
    final storagePath = '$userId/$fileName';

    // Upload dans le storage
    await _client.storage.from(bucket).upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

    // Enregistrement dans la table "files"
    await _client.from('files').insert({
      'filename': fileName,
      'path': storagePath,
      'user_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
    });

  }
}
