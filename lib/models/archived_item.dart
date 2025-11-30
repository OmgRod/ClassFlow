/// Model for archived items (subjects, books, etc.)
class ArchivedItem {
  String id; // UUID of archived item
  String type; // 'subject', 'book', 'lesson', etc.
  Map<String, dynamic> data; // Original item data as JSON
  DateTime archivedAt;
  String? reason; // Optional reason for archiving

  ArchivedItem({
    required this.id,
    required this.type,
    required this.data,
    DateTime? archivedAt,
    this.reason,
  }) : archivedAt = archivedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'archivedAt': archivedAt.toIso8601String(),
      'reason': reason,
    };
  }

  factory ArchivedItem.fromJson(Map<String, dynamic> json) {
    return ArchivedItem(
      id: json['id'] as String,
      type: json['type'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      archivedAt: DateTime.parse(json['archivedAt'] as String),
      reason: json['reason'] as String?,
    );
  }

  @override
  String toString() {
    return 'ArchivedItem(id: $id, type: $type, archivedAt: $archivedAt)';
  }
}
