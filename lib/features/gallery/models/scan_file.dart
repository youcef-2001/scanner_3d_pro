class ScanFile {
  final String id;
  final String filename;
  final String path;
  final DateTime createdAt;

  ScanFile({
    required this.id,
    required this.filename,
    required this.path,
    required this.createdAt,
  });

  factory ScanFile.fromJson(Map<String, dynamic> json) {
    return ScanFile(
      id: json['id'] as String,
      filename: json['filename'] as String,
      path: json['path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}