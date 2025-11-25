// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonAdapter extends TypeAdapter<Lesson> {
  @override
  final int typeId = 2;

  @override
  Lesson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lesson(
      id: fields[0] as String,
      subjectId: fields[1] as int,
      dayOfWeek: fields[2] as int,
      startHour: fields[3] as int,
      startMinute: fields[4] as int,
      endHour: fields[5] as int,
      endMinute: fields[6] as int,
      recurrenceType: fields[7] as RecurrenceType,
      customIntervalWeeks: fields[8] as int?,
      startDate: fields[9] as DateTime?,
      templateId: fields[10] as String?,
      notes: fields[11] as String?,
      weekNumber: fields[12] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Lesson obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.dayOfWeek)
      ..writeByte(3)
      ..write(obj.startHour)
      ..writeByte(4)
      ..write(obj.startMinute)
      ..writeByte(5)
      ..write(obj.endHour)
      ..writeByte(6)
      ..write(obj.endMinute)
      ..writeByte(7)
      ..write(obj.recurrenceType)
      ..writeByte(8)
      ..write(obj.customIntervalWeeks)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.templateId)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.weekNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceTypeAdapter extends TypeAdapter<RecurrenceType> {
  @override
  final int typeId = 3;

  @override
  RecurrenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceType.everyWeek;
      case 1:
        return RecurrenceType.everyTwoWeeks;
      case 2:
        return RecurrenceType.custom;
      default:
        return RecurrenceType.everyWeek;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceType obj) {
    switch (obj) {
      case RecurrenceType.everyWeek:
        writer.writeByte(0);
        break;
      case RecurrenceType.everyTwoWeeks:
        writer.writeByte(1);
        break;
      case RecurrenceType.custom:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
