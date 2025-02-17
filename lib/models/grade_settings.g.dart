// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GradeSettingsAdapter extends TypeAdapter<GradeSettings> {
  @override
  final int typeId = 200;

  @override
  GradeSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GradeSettings()
      ..version = fields[4] as int
      ..ALONKA_CREDIT = fields[5] as double
      ..GERIKAN_CREDIT = fields[6] as double
      ..RUNNER_CREDIT = fields[7] as double
      ..PARTICIPATION_CREDIT = fields[8] as double
      ..listOfCommentsBur = (fields[9] as List).cast<String>()
      ..listOfCommentsPerformance = (fields[10] as List).cast<String>()
      ..listOfCommentsImpression = (fields[11] as List).cast<String>()
      ..systemGradeFactor = fields[12] as double;
  }

  @override
  void write(BinaryWriter writer, GradeSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(4)
      ..write(obj.version)
      ..writeByte(5)
      ..write(obj.ALONKA_CREDIT)
      ..writeByte(6)
      ..write(obj.GERIKAN_CREDIT)
      ..writeByte(7)
      ..write(obj.RUNNER_CREDIT)
      ..writeByte(8)
      ..write(obj.PARTICIPATION_CREDIT)
      ..writeByte(9)
      ..write(obj.listOfCommentsBur)
      ..writeByte(10)
      ..write(obj.listOfCommentsPerformance)
      ..writeByte(11)
      ..write(obj.listOfCommentsImpression)
      ..writeByte(12)
      ..write(obj.systemGradeFactor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
