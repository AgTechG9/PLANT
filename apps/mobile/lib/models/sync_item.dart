import 'dart:convert';

class SyncItem {
  final String id;
  final String cropType;
  final String? imageBase64;
  final String? localPath;
  final DateTime createdAt;
  final bool isSynced;
  final String? caseNumber;

  SyncItem({
    required this.id,
    required this.cropType,
    this.imageBase64,
    this.localPath,
    required this.createdAt,
    this.isSynced = false,
    this.caseNumber,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'cropType': cropType,
    'imageBase64': imageBase64,
    'localPath': localPath,
    'createdAt': createdAt.toIso8601String(),
    'isSynced': isSynced,
    'caseNumber': caseNumber,
  };

  factory SyncItem.fromMap(Map<String, dynamic> map) => SyncItem(
    id: map['id'],
    cropType: map['cropType'] ?? 'Cassava',
    imageBase64: map['imageBase64'],
    localPath: map['localPath'],
    createdAt: DateTime.parse(map['createdAt']),
    isSynced: map['isSynced'] ?? false,
    caseNumber: map['caseNumber'],
  );

  String toJson() => jsonEncode(toMap());
  factory SyncItem.fromJson(String source) => SyncItem.fromMap(jsonDecode(source));
}
