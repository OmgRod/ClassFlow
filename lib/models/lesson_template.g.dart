// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonTemplateAdapter extends TypeAdapter<LessonTemplate> {
  @override
  final int typeId = 4;

  @override
  LessonTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      startHour: fields[2] as int,
      startMinute: fields[3] as int,
      endHour: fields[4] as int,
      endMinute: fields[5] as int,
      description: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonTemplate obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.startHour)
      ..writeByte(3)
      ..write(obj.startMinute)
      ..writeByte(4)
      ..write(obj.endHour)
      ..writeByte(5)
      ..write(obj.endMinute)
      ..writeByte(6)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
