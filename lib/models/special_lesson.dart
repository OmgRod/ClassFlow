import 'package:hive/hive.dart';

class SpecialLesson {
  String id; // UUID
  DateTime date; // specific date this special lesson applies to
  int subjectId;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  String? originalLessonId; // optional reference to lesson being overridden
  String? notes;

  SpecialLesson({
    required this.id,
    required this.date,
    required this.subjectId,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.originalLessonId,
    this.notes,
  });
}

class SpecialLessonAdapter extends TypeAdapter<SpecialLesson> {
  @override
  final int typeId = 5;

  @override
  SpecialLesson read(BinaryReader reader) {
    final id = reader.readString();
    final date = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final subjectId = reader.readInt();
    final startHour = reader.readInt();
    final startMinute = reader.readInt();
    final endHour = reader.readInt();
    final endMinute = reader.readInt();
    final hasOriginal = reader.readBool();
    final originalLessonId = hasOriginal ? reader.readString() : null;
    final hasNotes = reader.readBool();
    final notes = hasNotes ? reader.readString() : null;
    return SpecialLesson(
      id: id,
      date: date,
      subjectId: subjectId,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      originalLessonId: originalLessonId,
      notes: notes,
    );
  }

  @override
  void write(BinaryWriter writer, SpecialLesson obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.subjectId);
    writer.writeInt(obj.startHour);
    writer.writeInt(obj.startMinute);
    writer.writeInt(obj.endHour);
    writer.writeInt(obj.endMinute);
    writer.writeBool(obj.originalLessonId != null);
    if (obj.originalLessonId != null) writer.writeString(obj.originalLessonId!);
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) writer.writeString(obj.notes!);
  }
}
