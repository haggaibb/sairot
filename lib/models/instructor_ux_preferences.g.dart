// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instructor_ux_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstructorUxPreferencesAdapter
    extends TypeAdapter<InstructorUxPreferences> {
  @override
  final int typeId = 104;

  @override
  InstructorUxPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstructorUxPreferences(
      fontSize: fields[0] as double,
      theme: fields[1] as String,
      inOrderOfArrival: fields[2] as bool,
      floatingPttEnabled: fields[3] as bool,
      volumeButtonPttEnabled: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, InstructorUxPreferences obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.fontSize)
      ..writeByte(1)
      ..write(obj.theme)
      ..writeByte(2)
      ..write(obj.inOrderOfArrival)
      ..writeByte(3)
      ..write(obj.floatingPttEnabled)
      ..writeByte(4)
      ..write(obj.volumeButtonPttEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstructorUxPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
