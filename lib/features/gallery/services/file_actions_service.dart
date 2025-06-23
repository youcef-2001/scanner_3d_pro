import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scan_file.dart';
import '../widgets/stl_viewer.dart';



class FileActionsService {
  final _client = Supabase.instance.client;
  final String bucket = 'scans';

  void view(BuildContext context, ScanFile file) {
    final url = _client.storage.from(bucket).getPublicUrl(file.path);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => STLViewer(fileUrl: url),
      ),
    );
  }

  Future<void> share(BuildContext context, ScanFile file) async {
    final url = _client.storage.from(bucket).getPublicUrl(file.path);

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 8,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text('Copier le lien', style: TextStyle(color: Colors.white)),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien copié 📋')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Partager via une app', style: TextStyle(color: Colors.white)),
              onTap: () {
                Share.share('Voici un fichier 3D :\n$url');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> rename(BuildContext context, ScanFile file) async {
    final controller = TextEditingController(text: file.filename);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renommer le fichier'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Valider')),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && result.trim() != file.filename.trim()) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur non connecté")),
        );
        return false;
      }

      try {
        final response = await _client.from('files').update({
          'filename': result.trim(),
        }).eq('id', file.id).eq('user_id', user.id);

        print('✅ RENAME (DB only): $response');
        return true;
      } catch (e) {
        print('❌ ERROR during rename (DB only): $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors du renommage")),
        );
      }
    }

    return false;
  }

  Future<bool> delete(BuildContext context, ScanFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer "${file.filename}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur non connecté")),
        );
        return false;
      }

      try {
        await _client.storage.from(bucket).remove([file.path]);

        final response = await _client
            .from('files')
            .delete()
            .eq('id', file.id)
            .eq('user_id', user.id); // ✅ important pour respecter la policy DELETE

        print('⛳ DELETE RESULT: $response');
        return true;
      } catch (e) {
        print('❌ ERROR while deleting file from table: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la suppression")),
        );
      }
    }

    return false;
  }


}
