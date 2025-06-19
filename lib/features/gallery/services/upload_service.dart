import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class UploadService {
  final _supabase = Supabase.instance.client;
  final _bucket = 'scans';

  Future<void> uploadSTL(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Non connecté.");

    final filename = file.path.split('/').last;
    final storagePath = '${user.id}/$filename';

    // Upload dans Storage
    print('>>> Fichier sélectionné : ${file.path}');
    print('>>> Tentative upload vers : $storagePath');
    print('>>> user.id côté client Flutter : ${user.id}');
    print('>>> Supabase auth.uid() : ${_supabase.auth.currentUser?.id}');
    final response = await _supabase.storage.from(_bucket).upload(
      storagePath,
      file,
      fileOptions: const FileOptions(contentType: 'application/sla'),
    );
    print('>>> Réponse Storage : $response');
    if (response.isEmpty) throw Exception("Erreur upload.");

    // Enregistrer dans la table `files`

    print('>>> user_id dans la requête : ${user.id}');

    await _supabase.from('files').insert({
      'id': const Uuid().v4(),
      'user_id': user.id,
      'filename': filename,
      'path': storagePath,
    });
    print('>>> Insertion dans la base réussie');
  }
}