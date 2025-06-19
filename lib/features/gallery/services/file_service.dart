import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scan_file.dart';

class FileService {
  final supabase = Supabase.instance.client;

  Future<List<ScanFile>> getUserFiles() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('files')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;

    return data.map((item) => ScanFile.fromJson(item)).toList();
  }
}
