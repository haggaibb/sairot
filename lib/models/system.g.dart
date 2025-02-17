// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SystemAdapter extends TypeAdapter<System> {
  @override
  final int typeId = 102;

  @override
  System read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return System()
      ..loggedIn = fields[0] as String
      ..instructors = (fields[1] as List).cast<Instructor>()
      ..gradeSettings = fields[2] as GradeSettings
      ..systemSettings = fields[3] as SystemSettings;
  }

  @override
  void write(BinaryWriter writer, System obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.loggedIn)
      ..writeByte(1)
      ..write(obj.instructors)
      ..writeByte(2)
      ..write(obj.gradeSettings)
      ..writeByte(3)
      ..write(obj.systemSettings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
