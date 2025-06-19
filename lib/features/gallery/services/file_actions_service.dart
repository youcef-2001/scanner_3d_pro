import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scan_file.dart';

class FileActionsService {
  final _client = Supabase.instance.client;
  final String bucketName = 'scans';

  Future<String> _getSignedUrl(String path) async {
    final res = await _client.storage
        .from(bucketName)
        .createSignedUrl(path, 60 * 10);
    return res;
  }

  void view(BuildContext context, ScanFile file) async {
    final url = await _client.storage
        .from('scans')
        .createSignedUrl(file.path, 60 * 10); // valable 10 min

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: SizedBox(
          width: 300,
          height: 300,
          child: ModelViewer(
            src: url,
            alt: '3D Model',
            autoRotate: true,
            cameraControls: true,
          ),
        ),
      ),
    );
  }

  Future<void> share(BuildContext context, ScanFile file) async {
    final url = await _getSignedUrl(file.path);

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
              title: const Text('Copier dans le presse-papiers', style: TextStyle(color: Colors.white)),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien copié dans le presse-papiers 📋')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Partager via une app', style: TextStyle(color: Colors.white)),
              onTap: () {
                Share.share('Voici mon fichier 3D partagé depuis l\'app :\n$url');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> rename(BuildContext context, ScanFile file) async {
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

    if (result != null && result != file.filename) {
      await _client.from('files').update({'filename': result}).eq('id', file.id);
    }
  }

  Future<void> delete(BuildContext context, ScanFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer le fichier "${file.filename}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirm == true) {
      await _client.storage.from(bucketName).remove([file.path]);
      await _client.from('files').delete().eq('id', file.id);
    }
  }
}
